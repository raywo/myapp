# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, key: '_myapp_session', domain: {
    production:   '.myapp.com',
    staging:      '.myapp.com',
    development:  '.lvh.me'
}.fetch(Rails.env.to_sym, :all)
