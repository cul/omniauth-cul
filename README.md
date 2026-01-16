# Omniauth::Cul

Omniauth::Cul is a gem that facilitates using Rails, [Devise](https://github.com/plataformatec/devise "Devise") and Omniauth with the [CAS offering from Columbia University IT](https://cuit.columbia.edu/cas-authentication "CUIT CAS Documentation").

At this time, this gem only supports Columbia University's CAS3 authentication endpoint (which provides user affiliation information), but support for additional auth mechanisms may be added later if needed.

## Installation and setup

The instructions below assume that your Rails application's user model will be called "User".

1. Add gem `devise` (~> 4.9) to your Gemfile. (This gem has only been tested with Devise 4.x.)
2. Follow the standard Devise setup instructions (https://github.com/heartcombo/devise).  Recap:
   1. `rails generate devise:install`
   2. `rails generate devise User`
   3. `rails db:migrate`
3. Add gem `omniauth` (~> 2.1) to your Gemfile.
4. Add this gem, 'omniauth-cul', to your Gemfile. (This gem has only been tested with omniauth 2.x.)
5. Run `bundle install`.
6. Add an initializer to your app at `/config/initializers/omniauth.rb` with this content in it (to mitigate):
   1. ```
      OmniAuth.config.request_validation_phase = OmniAuth::AuthenticityTokenProtection.new(key: :_csrf_token)
      ```
   2. For more info, see: https://github.com/cookpad/omniauth-rails_csrf_protection?tab=readme-ov-file#omniauth---rails-csrf-protection
7. This gem offers two Omniauth providers:
   - `:columbia_cas` - For logging in with a Columbia UNI
   - `:developer_uid` - For logging in as a user with a specific uid (IMPORTANT: only enable this in a development environment!)

   To enable one or both of these providers, edit `/config/initializers/devise.rb` and add one or both of these lines:
   ```
   config.omniauth :columbia_cas, { label: 'Columbia SSO (CAS)' }
   config.omniauth :developer_uid, { label: 'Developer UID' } if Rails.env.development?
   ```
   (NOTE: You may already have other config.omniauth entries in your devise.rb file. If so, you can append the lines above to that section.)
8. Add a :uid column to the User model by running: `rails generate migration AddUidToUsers uid:string:uniq:index`
9.  In `/app/models/user.rb`, find the line where the `devise` method is called.
   - It might look something like this:
      ```
      devise :database_authenticatable, :validatable
      ```
   - Minimally, you need to add these additional arguments to the end of the method call: `:omniauthable, omniauth_providers: Devise.omniauth_configs.keys`, so the updated code might look like this:
     ```
     devise :database_authenticatable, :validatable, :omniauthable, omniauth_providers: Devise.omniauth_configs.keys
     ```
     This is just an example though!  You might not need the `:database_authenticatable` and `:validatable` modules for your app.  See the [Devise documentation](https://github.com/heartcombo/devise) for more information about available modules and what they do.

      It's worth mentioning here that if you use plan to use omniauth-cul gem for CAS authentication, you might not actually want to support password authentication in your app anymore.  If that's the case, you can remove the `:database_authenticatable` module (which enforces the presence of an `encrypted_password` field on your User model) and you can also remove the `:validatable` model (which, among other things, validates the presence of a password field when a new User is created).

    - The simplest version of your devise configuration could look like this:
      ```
      devise :omniauthable, omniauth_providers: Devise.omniauth_configs.keys
      ```
      Why does `:omniauth_providers` configuration has a value of `Devise.omniauth_configs.keys`?  This serves the purpose of automatically referencing any config.omniauth providers that you previously enabled in `devise.rb`.  For example, if you enabled `:columbia_cas` and `:developer_uid` providers in `devise.rb`, then `Devise.omniauth_configs.keys` would return `[:columbia_cas, :developer_uid]`.
10. In `/config/routes.rb`, find this line:
   ```
    devise_for :users
   ```
   And replace it with this:
   ```
    devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
   ```
11. Create a new file at `app/controllers/users/omniauth_callbacks_controller.rb` with the following content (and then customize it based on your needs):
    ```
    require 'omniauth/cul'

    class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
      # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
      # The CAS login redirect to the columbia_cas callback endpoint AND the developer form submission to the
      # developer_uid callback do not send authenticity tokens, so we'll skip token verification for these actions.
      skip_before_action :verify_authenticity_token, only: [:columbia_cas, :developer_uid]

      # POST /users/auth/developer_uid/callback
      def developer_uid
        return unless Rails.env.development? # Only allow this action to run in the development environment
        uid = params[:uid]
        user = User.find_by(uid: uid)

        if !user
          flash[:alert] = "Login attempt failed.  User #{uid} does not have an account."
          redirect_to root_path
          return
        end

        sign_in_and_redirect user, event: :authentication # this will throw if user is not activated
      end

      # POST /users/auth/columbia_cas/callback
      def columbia_cas
        callback_url = user_columbia_cas_omniauth_callback_url # The columbia_cas callback route in this application
        uid, _affils = Omniauth::Cul::ColumbiaCas.validation_callback(request.params['ticket'], callback_url)

        # Custom auth logic for your app goes here.
        # The code below is only provided as an example.  If you want to use Omniauth::Cul::PermissionFileValidator,
        # to validate see the later "Omniauth::Cul::PermissionFileValidator" section of this README.
        #
        # if Omniauth::Cul::PermissionFileValidator.permitted?(uid, _affils)
        #   user = User.find_by(uid: uid) || User.create!(
        #     uid: uid,
        #     email: "#{uid}@columbia.edu",
        #     # Only keep the line below if you're using the :database_authenticatable Devise module.
        #     # Omniauth login doesn't use a password (so the password value doesn't matter to Omniauth),
        #     # but your app's setup might require a password to be assigned to new users.
        #     password: Devise.friendly_token[0, 20]
        #   )
        #   sign_in_and_redirect user, event: :authentication # this will throw if user is not activated
        # else
        #   flash[:alert] = 'Login attempt failed'
        #   redirect_to root_path
        # end
      rescue Omniauth::Cul::Exceptions::Error => e
        # If an unexpected CAS ticket validation occurs, log the error message and ask the user to try
        # logging in again.  Do not display the exception object's original message to the user because it may
        # contain information that only a developer should see.
        error_message = 'CAS login validation failed.  Please try again.'
        Rails.logger.debug(error_message + "  #{e.class.name}: #{e.message}")
        flash[:alert] = error_message
        redirect_to root_path
      end
    end
    ```
  12. The last thing to note is that you must POST to any /users/auth/:provider paths when your users log in via Omniauth.  For security reasons in Omniauth 2.0 and later, use of GET is discouraged and will not work for the Omniauth strategies provided by this gem.  In the past, if you used the Rails `link_to` method to generate links to `/users/auth/:provider`, you should instead use `button_to` because it will generate a `<form method="post">` tag that will perform a POST request to your `/users/auth/:provider` URLs.  If you attempt a GET request, you'll most likely get an error message that says something like "Not found. Authentication passthru."

## Omniauth::Cul::PermissionFileValidator - Permission validation with a user id list or affiliation list

One of the modules in this gem is `Omniauth::Cul::PermissionFileValidator`, which can be used like this:

```
user_id = 'abc123'
affils = ['affil1']
if Omniauth::Cul::PermissionFileValidator.permitted?(user_id, affils)
  # This block will run if your Rails app has a file at /config/permissions.yml that
  # permits access for user 'abc123' OR any user with affiliation 'affil1'.
end
```

In your Rails app, your permission.yml file should be located at /config/permissions.yml.  For each environment, you may define allowed_user_ids and/or allowed_user_affils.

```
# Permissions

all: &all
  allowed_user_ids:
    - abc123
    - def123
    - ghi123
  allowed_user_affils:
    - CUL_dpts-ldpd

development: *all
test: *all
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).
