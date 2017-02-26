class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :redirect_to_app_url

  # GET /homes
  # GET /homes.json
  def index
  end # index
end # class
