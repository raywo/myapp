class SubdomainConstraint
  def self.matches?(request)
    excluded_subdomains = ExcludedSubdomains.subdomains
    request.subdomain.present? && !excluded_subdomains.include?(request.subdomain)
  end # matches?
end # class
