##
# Wird eine Subdomain aufgerufen, für die es keinen Mandanten gibt
# (`TenantNotFound`), soll auf die Startseite umgeleitet werden.
##
module RescuableApartmentMiddleware
  def call(*args)
    begin
      super
    rescue Apartment::TenantNotFound
      redirect_url = Rails.application.routes.url_helpers.url_for(controller: 'website',
                                                                  action: :index)
      return [ 301, { 'Location' => redirect_url }, [ 'redirect' ] ]
    end
  end # call
end # module
