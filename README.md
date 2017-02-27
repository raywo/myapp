# MyApp – Subdomains, Apartment and Devise

This is an example app for multitenancy with [Apartment](https://github.com/influitive/apartment), [Devise](https://github.com/plataformatec/devise) and subdomains.
It was built by me to track down a bug I had in another project. Maybe this can be a good example for someone who wants to start a new project with multitenancy, Apartment and Devise.

The bug I was tracking down was that signing in from a subdomain like `app.myapp.com` wouldn’t work. Due to some DDNS issues this is crucial for my project. Signing in form `myapp.com` worked like charm but not from the subdomain. 

I tried everything I found on [stackoverflow.com](http://www.stackoverflow.com) and the likes. But nothing worked for me. I even asked a [question](http://stackoverflow.com/questions/42467757/rails-5-apartment-and-devise-sign-in-with-subdomains-are-not-working) in hope of getting help. The answer I get was not very helpful since I already tried that. At least that was what I thought. 

I started this app from scratch to prove the guy who answered me wrong. After some copy and pasting from my faulty project to this app my project suddenly worked as it should be. I don’t know why. I don’t know what I changed to make it work eventually but it works. And I am happy. Since this app already exists I thought I could share it.

Since even demo app need to be nice I used [Bootstrap 4](https://github.com/twbs/bootstrap-rubygem) to let the app look like something important.


## What this app does
It does not much but enough to show how Apartment and Devise are working together using subdomains for each tenant. Each devise user is considerd to be a tenant in Apartment. The user models stores a `subdomain` attribute for each user. So a user can be redirected to their own subdomain after signing in.

 
 ## Installation
1. Download or clone the project.
 
2. Adjust `/config/database.yml` to your needs.
    
   I choose postgres for this little project because I wanted to see how Apartment would work with multiple schemas. If you don’t have postgres or you want to use another database adjust the settings accordingly.
    
3. Run `bundle install`.
 
4. Run `rake db:setup`.
 
   Be sure that you have edited your `database.yml` before running this rake task!
    
   I’ve included no seed data. So you can start from scratch by registering your users.
    
5. Start the server and use the app. 

   **Remember:** Since `localhost` doesn’t suppurt subdomains use `lvh.me` instead. This domain points to 127.0.0.1 which is your localhost and since it is a real domain it supports subdomains.


## The inner workings

### Users and Tenants
As every user is also a tenant the tenant must be created in apartment at the same time a new user record is created. This is achieved by an `after_create` hook in the user model. Of course a tenant must also be deleted when the user record is deleted. Hence the `after_destroy` hook.

```ruby
class User
  after_create :create_tenant
  after_destroy :delete_tenant
  
  def create_tenant
    Apartment::Tenant.create(subdomain)
  end # create_tenant
  
  
  def delete_tenant
    Apartment::Tenant.drop(subdomain)
  end # delete_tenant
end # class
```

The extra attribute `subdomain` is asked when signing up. Although it would be sufficient to follow [these steps](https://github.com/plataformatec/devise#strong-parameters) to allow additional parameters like `subdomain` I decided to use my own Devise controllers as described [here](https://github.com/plataformatec/devise#configuring-controllers). Of course you need to provide an extra textfield in the sign up form. That’s why I generated the views too. (Described [here](https://github.com/plataformatec/devise#configuring-views).)

### Routing to subdomains
Central feature of this app is that every signed in user will be presented their own ”Dashboard“ which can only be accessed through their own subdomain. For this to work you will need two things. ”Hiding“ the `DashboardController` and redirecting signed in users to their dashboard.


#### ”Hiding“ the `DashboardController`
First the `DashboardController` must be ”hidden“ so that it’s views can only be accessed via a prepended subdomain generating a 404 error when accessed without a subdomain. This is done by telling the router to constrain this resource to the presence of subdomains:

```ruby
Rails.application.routes.draw do
  root to: 'home#index'

  devise_for :users, controllers: {
    registrations:  'users/registrations',
    sessions:       'users/sessions',
    passwords:      'users/passwords',
  }

  constraints SubdomainConstraint do
    get 'dashboard/index'
  end # constraints

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
```

`SubdomainContrained` is a class located at `/app/classes`. It makes sure that a) a subdomain is present and b) the subdomain is not an excluded subdomain. (Read more about excluded subdomains [here](https://github.com/influitive/apartment#excluding-models).) Excluded subdomains are declared as an array in `ExcludedSubdomains`.  In my original app I needed the information about which subdomains are excluded in various different places. So I extracted this information out in a separate class.

#### Redirecting the user to their subdomain
The second thing which is needed to let the app do what it should do is to redirect every signed in user to their own subdomain. This is done by the `ApplicationController`.

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_user!
  # Every logged in user should be redirected to their own subdomain
  before_action :redirect_to_subdomain

  # other stuff is happening here…
  
  def redirect_to_subdomain
    return if self.is_a?(DeviseController)
    
    if current_user.present? && request.subdomain != current_user.subdomain
      subdomain = current_user.subdomain
      host = request.host_with_port.sub! "#{request.subdomain}", subdomain

      redirect_to "http://#{host}#{request.path}"
    end # if
  end # redirect_to_subdomain
end # class
```

## The `HomeController`
Of course the app needs a starting page from where users can sign up and sign in. This view is delivered by the `HomeController`. Routes regaring this controllers are not constrained to subdomains.

Instead of redirecting to a user’s subdomain the `HomeController` redirects to the app url which is the url prepended with `app` e.g `app.myapp.com`.

```ruby
class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :redirect_to_app_url

  # GET /homes
  # GET /homes.json
  def index
  end # index
end # class
```

## Devise Authentication
Devise stores the information about a signed in user in a cookie. Cookies are not shared across domains by default. So signing in from `subdomain1.mayapp.com` and then visiting `subdomain2.myapp.com` would lead to an authentication error. By default Devise redirects then to the sign in page.

This is exactly the opposite of what I had in mind. Signing in via `app.myapp.com` and then being redirected to another subdomain was the crucial requirement.

To make that work you have to tell the app to share cookies across subdomains. This is done by editing `/config/initializers/session_store.rb` like so:

```ruby
# /config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store, key: '_myapp_session', domain: {
  production:   '.myapp.com',
  staging:      '.myapp.com',
  development:  '.lvh.me'
}.fetch(Rails.env.to_sym, :all)
``` 

Please note the leading `.`! This is necessary to tell the app to share cookies across `myapp.com` and all it’s subdomains.

Tested with:

* Ruby version: 2.3.3
* Rails version: 5.0.1
* Apartment: 1.2.0
* Devise: 4.2.0
* Bootstrap: 4.0.0.alpha6
* SimpleForm: 3.4.0
* Database: Postgres (pg gem 0.19.0)
