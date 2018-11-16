require 'net/http'
require 'uri'
require 'json'

class DomainManager

  def initialize
    self.v1_token = ENV['v1_token']
    self.user_token = ENV['user_token']
    self.user_email = ENV['user_email']
    self.account_id = ENV['account_id']
  end
	
  def ask_user 
    puts 'enter a domain you want to look up:'
    input = gets.chomp
    puts 'checking...'
    domain_lookup(input)
  end

  def domain_lookup(input)
    search = search_for_domain(input)
    parsed_response = JSON.parse(search.body)
    answer = handle_user_options(input, parsed_response)
    handle_user_selection(answer)
  end

  def handle_user_options(input, parsed_response)
    parsed_response['available'] ? puts "domain status: AVAILABLE" : puts "domain status: NOT AVAILABLE"
    puts "what would you like to do?"
    puts "1) type 'buy' to buy #{input} for #{parsed_response['currency_symbol']} #{parsed_response['price']}"
    puts "2) type 'search' to search for another domain"
    puts "3) type 'exit' to leave"
    answer = gets.chomp.strip
  end

  def handle_user_selection(answer)
    case answer
    when 'buy'
      begin_registration(input)
    when 'search'
      ask_user
    else 
      puts 'okay bye!'
      exit
    end
  end

  def search_for_domain(input)
    uri = URI.parse("https://api.dnsimple.com/v1/domains/#{input}/check")
    request = get_request(uri)
    req_options = set_req_options(uri)
    response = create_request(uri, req_options, request)
  end

  def begin_registration(domain_name)
    contacts = JSON.parse(list_accounts.body)
    if !contacts["data"].nil?
      contact_id = get_contact_id(contacts)
    else
      ask_to_create_contact(domain_name)
    end

    return unless !contact_id.nil?
    
    domain = register_domain(domain_name, contact_id)
    # domain.body
  end

  def get_contact_id(contacts)
    puts 'select the contact you would like to use to register this domain'
    contacts["data"].each do |c|
      puts "-Please enter '" + c["id"].to_s + "' to choose " + c["first_name"] + " " + c["last_name"] + ' as the primary contact for this domain'
    end
    contact_id = gets.chomp.strip
  end

  def register_domain(domain_name, contact_id)
    uri = URI.parse("https://api.dnsimple.com/v2/#{self.account_id}/registrar/domains/#{domain_name}/registrations")
    request = post_request(uri)
    request.body = { registrant_id: contact_id, whois_privacy: true }.to_json
    req_options = set_req_options(uri)
    response = create_request(uri, req_options, request)
  end

  def list_accounts
    uri = URI.parse("https://api.dnsimple.com/v2/#{self.account_id}/contacts")
    request = post_request(uri)
    req_options = set_req_options(uri)
    response = create_request(uri, req_options, request)
    # response.body
  end

  def get_request(uri)
    request = Net::HTTP::Get.new(uri)
    request["X-Dnsimple-Token"] = "#{self.user_email}:#{self.v1_token}"
    request["Accept"] = "application/json"
  end

  def post_request(uri)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{self.user_token}"
    request["Accept"] = "application/json"
  end

  def set_req_options(uri)
    req_options = {
      use_ssl: uri.scheme == "https",
    }
  end

  def ask_to_create_contact(domain_name)
    puts 'No contacts exist yet for your account. Would you like to create one? Type "yes" to create a new contact.'
    answer = gets.chomp.strip 
    if answer == 'yes'
      create_account_contact
      begin_registration(domain_name)
    else
      return
    end    
  end

  def create_account_contact
    uri = URI.parse("https://api.dnsimple.com/v2/#{self.account_id}/contacts")
    request = post_request(uri)
    request.body = {
      first_name: 'First Name',
      last_name: 'Last Name',
      address1: '1 Broadway',
      city: 'New York',
      state_province: 'NY',
      postal_code: '10000',
      country: 'USA',
      email: 'hello@example.com',
      phone: '+15555555555',
      fax: '+15555555555'
    }.to_json
    req_options = set_req_options(uri)
    response = create_request(uri, req_options, request)
  end

  def create_request(uri, req_options, request)
    Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }
  end
end

# domain_manager = DomainManager.new
# domain_manager.ask_user
