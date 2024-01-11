# Cul::Omniauth

Cul::Omniauth is a gem that facilitates using Rails, [Devise](https://github.com/plataformatec/devise "Devise") and Omniauth with the [CAS offering from Columbia University IT](https://cuit.columbia.edu/cas-authentication "CUIT CAS Documentation").

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
6. In `/app/models/user.rb`, find the line where the `devise` method is called (usually with arguments like `:database_authenticatable`, `:registerable`, etc.).  Add these additional arguments to the end of the method call: `:omniauthable, omniauth_providers: [:cas]`
7. In `/config/routes.rb`, find this line:
   ```
    devise_for :users
   ```
   And replace it with this:
   ```
    devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
   ```
8. Create a new file at `app/controllers/users/omniauth_callbacks_controller.rb` with the following content:
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
            uni, affils = Omniauth::Cul::Cas3.validation_callback(request.params['ticket'], app_cas_callback_endpoint)

            # Custom auth logic for your app goes here.
            # The code below is provided as an example.
            #
            # if Omniauth::Cul::PermissionFileValidator.permitted?(uni, affils)
            #     user = User.find_by(uid: uni) || User.create!(
            #         uid: uni,
            #         email: "#{uni}@columbia.edu"
            #     )
            #     sign_in_and_redirect user, event: :authentication # this will throw if @user is not activated
            # else
            #     flash[:error] = 'Login attempt failed'
            #     redirect_to root_path
            # end
        end
    end
   ```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).
