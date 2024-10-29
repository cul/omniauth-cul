# Omniauth::Cul

Omniauth::Cul is a gem that facilitates using Rails, [Devise](https://github.com/plataformatec/devise "Devise") and Omniauth with the [CAS offering from Columbia University IT](https://cuit.columbia.edu/cas-authentication "CUIT CAS Documentation").

At this time, this gem only supports Columbia University's CAS3 authentication endpoint (which provides user affiliation information), but support for additional auth mechanisms may be added later if needed.

## Installation and setup

The instructions below assume that your Rails application's user model will be called "User".

1. Add gem `devise` (>= 4.9) to your Gemfile.
2. Follow the standard Devise setup instructions (https://github.com/heartcombo/devise).  Recap:
   1. `rails generate devise:install`
   2. `rails generate devise User`
   3. `rails db:migrate`
3. Add gem `omniauth` (>= 2.1) to your Gemfile.
4. Add this gem, 'omniauth-cul', to your Gemfile.
5. Run `bundle install`.
6. In `/config/initializers/devise.rb`, add this:
   ```
   config.omniauth :cas, strategy_class: Omniauth::Cul::Strategies::Cas3Strategy
   ```
   (There may already be a config.omniauth section, and if so you can append this to the existing lines in that section.)
7. Add a :uid column to the User model by running: `rails generate migration AddUidToUsers uid:string:uniq:index`
8. In `/app/models/user.rb`, find the line where the `devise` method is called (usually with arguments like `:database_authenticatable`, `:registerable`, etc.).
   - Minimally, you need to add these additional arguments to the end of the method call: `:omniauthable, omniauth_providers: [:cas]`
   - In most cases though, you'll probably want to disable most of the modules and have only this:
      ```
      devise :database_authenticatable, :validatable, :omniauthable, omniauth_providers: [:cas]
      ```
9.  In `/config/routes.rb`, find this line:
   ```
    devise_for :users
   ```
   And replace it with these lines:
   ```
    devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
   ```
10. Create a new file at `app/controllers/users/omniauth_callbacks_controller.rb` with the following content:
    ```
    require 'omniauth/cul'

      class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
        # Adding the line below so that if the auth endpoint POSTs to our cas endpoint, it won't
        # be rejected by authenticity token verification.
        # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
        skip_before_action :verify_authenticity_token, only: :cas

        def app_cas_callback_endpoint
          "#{request.base_url}/users/auth/cas/callback"
        end

        # GET /users/auth/cas (go here to be redirected to the CAS login form)
        def passthru
          redirect_to Omniauth::Cul::Cas3.passthru_redirect_url(app_cas_callback_endpoint), allow_other_host: true
        end

        # GET /users/auth/cas/callback
        def cas
          user_id, affils = Omniauth::Cul::Cas3.validation_callback(request.params['ticket'], app_cas_callback_endpoint)

          # Custom auth logic for your app goes here.
          # The code below is provided as an example.  If you want to use Omniauth::Cul::PermissionFileValidator,
          # to validate see the later "Omniauth::Cul::PermissionFileValidator" section of this README.
          #
          # if Omniauth::Cul::PermissionFileValidator.permitted?(user_id, affils)
          #   user = User.find_by(uid: user_id) || User.create!(
          #       uid: user_id,
          #       email: "#{user_id}@columbia.edu",
          #       password: Devise.friendly_token[0, 20] # Assign random string password, since the omniauth user doesn't need to know the unused local account password
          #   )
          #   sign_in_and_redirect user, event: :authentication # this will throw if @user is not activated
          # else
          #   flash[:error] = 'Login attempt failed'
          #   redirect_to root_path
          # end
        end
      end
    ```

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
