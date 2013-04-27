require 'spec_helper'

describe Dyndnsd::Daemon do
  include Rack::Test::Methods
  
  def app
    config = {
      'domain' => 'example.org',
      'users' => {
        'test' => {
          'password' => 'secret',
          'hosts' => ['foo.example.org', 'bar.example.org']
        }
      }
    }
    db = Dyndnsd::DummyDatabase.new({})
    updater = Dyndnsd::Updater::Dummy.new
    responder = Dyndnsd::Responder::DynDNSStyle.new
    app = Dyndnsd::Daemon.new(config, db, updater, responder)
    
    Rack::Auth::Basic.new(app, "DynDNS") do |user,pass|
      (config['users'].has_key? user) and (config['users'][user]['password'] == pass)
    end
  end
  
  it 'requires authentication' do
    get '/'
    last_response.status.should == 401
    
    pending 'Need to find a way to add custom body on 401 responses'
    last_response.should be_ok 'badauth'
  end
  
  it 'only supports GET requests' do
    authorize 'test', 'secret'
    post '/nic/update'
    last_response.status.should == 405
  end
  
  it 'provides only the /nic/update' do
    authorize 'test', 'secret'
    get '/other/url'
    last_response.status.should == 404
  end
  
  it 'requires the hostname query parameter' do
    authorize 'test', 'secret'
    get '/nic/update'
    last_response.should be_ok
    last_response.body.should == 'notfqdn'
  end
  
  it 'forbids changing hosts a user does not own' do
    authorize 'test', 'secret'
    get '/nic/update?hostname=notmyhost.example.org'
    last_response.should be_ok
    last_response.body.should == 'nohost'
  end
  
  it 'updates a host on change' do
    authorize 'test', 'secret'
    
    get '/nic/update?hostname=foo.example.org&myip=1.2.3.4'
    last_response.should be_ok
    
    get '/nic/update?hostname=foo.example.org&myip=1.2.3.40'
    last_response.should be_ok
    last_response.body.should == 'good 1.2.3.40'
  end
  
  it 'returns no change' do
    authorize 'test', 'secret'
    
    get '/nic/update?hostname=foo.example.org&myip=1.2.3.4'
    last_response.should be_ok
    
    get '/nic/update?hostname=foo.example.org&myip=1.2.3.4'
    last_response.should be_ok
    last_response.body.should == 'nochg 1.2.3.4'
  end
  
  it 'forbids invalid hostnames' do
    authorize 'test', 'secret'
    
    get '/nic/update?hostname=test'
    last_response.should be_ok
    last_response.body.should == 'notfqdn'
    
    get '/nic/update?hostname=test.example.com'
    last_response.should be_ok
    last_response.body.should == 'notfqdn'
    
    get '/nic/update?hostname=test.example.org.me'
    last_response.should be_ok
    last_response.body.should == 'notfqdn'
    
    get '/nic/update?hostname=foo.test.example.org'
    last_response.should be_ok
    last_response.body.should == 'notfqdn'
    
    get '/nic/update?hostname=in%20valid.example.org.me'
    last_response.should be_ok
    last_response.body.should == 'notfqdn'
  end
  
  it 'outputs status for hostname' do
    authorize 'test', 'secret'

    get '/nic/update?hostname=foo.example.org&myip=1.2.3.4'
    last_response.should be_ok
    last_response.body.should == 'good 1.2.3.4'
  end
  
  it 'supports multiple hostnames in request' do
    authorize 'test', 'secret'
    
    pending
    
    get '/nic/update?hostname=foo.example.org,bar.example.org&myip=1.2.3.4'
    last_response.should be_ok
    last_response.body.should == "good 1.2.3.4\ngood 1.2.3.4"
  end
end
