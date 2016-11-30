require 'spec_helper'

describe Dyndnsd::Daemon do
  include Rack::Test::Methods

  def app
    Dyndnsd.logger = Logger.new(STDOUT)
    Dyndnsd.logger.level = Logger::UNKNOWN

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

  it 'provides only the /nic/update URL' do
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

  it 'supports multiple hostnames in request' do
    authorize 'test', 'secret'

    get '/nic/update?hostname=foo.example.org,bar.example.org&myip=1.2.3.4'
    last_response.should be_ok
    last_response.body.should == "good 1.2.3.4\ngood 1.2.3.4"

    get '/nic/update?hostname=foo.example.org,bar.example.org&myip=2001:db8::1'
    last_response.should be_ok
    last_response.body.should == "good 2001:db8::1\ngood 2001:db8::1"
  end

  it 'rejects request if one hostname is invalid' do
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

    get '/nic/update?hostname=in%20valid.example.org'
    last_response.should be_ok
    last_response.body.should == 'notfqdn'

    get '/nic/update?hostname=valid.example.org,in.valid.example.org'
    last_response.should be_ok
    last_response.body.should == 'notfqdn'
  end

  it 'rejects request if user does not own one hostname' do
    authorize 'test', 'secret'
    get '/nic/update?hostname=notmyhost.example.org'
    last_response.should be_ok
    last_response.body.should == 'nohost'

    get '/nic/update?hostname=foo.example.org,notmyhost.example.org'
    last_response.should be_ok
    last_response.body.should == 'nohost'
  end

  it 'updates a host on IP change' do
    authorize 'test', 'secret'

    get '/nic/update?hostname=foo.example.org&myip=1.2.3.4'
    last_response.should be_ok

    get '/nic/update?hostname=foo.example.org&myip=1.2.3.40'
    last_response.should be_ok
    last_response.body.should == 'good 1.2.3.40'

    get '/nic/update?hostname=foo.example.org&myip=2001:db8::1'
    last_response.should be_ok

    get '/nic/update?hostname=foo.example.org&myip=2001:db8::10'
    last_response.should be_ok
    last_response.body.should == 'good 2001:db8::10'
  end

  it 'returns IP no change' do
    authorize 'test', 'secret'

    get '/nic/update?hostname=foo.example.org&myip=1.2.3.4'
    last_response.should be_ok

    get '/nic/update?hostname=foo.example.org&myip=1.2.3.4'
    last_response.should be_ok
    last_response.body.should == 'nochg 1.2.3.4'

    get '/nic/update?hostname=foo.example.org&myip=2001:db8::1'
    last_response.should be_ok

    get '/nic/update?hostname=foo.example.org&myip=2001:db8::1'
    last_response.should be_ok
    last_response.body.should == 'nochg 2001:db8::1'
  end

  it 'outputs IP status per hostname' do
    authorize 'test', 'secret'

    get '/nic/update?hostname=foo.example.org&myip=1.2.3.4'
    last_response.should be_ok
    last_response.body.should == 'good 1.2.3.4'

    get '/nic/update?hostname=foo.example.org,bar.example.org&myip=1.2.3.4'
    last_response.should be_ok
    last_response.body.should == "nochg 1.2.3.4\ngood 1.2.3.4"

    get '/nic/update?hostname=foo.example.org&myip=2001:db8::1'
    last_response.should be_ok
    last_response.body.should == 'good 2001:db8::1'

    get '/nic/update?hostname=foo.example.org,bar.example.org&myip=2001:db8::1'
    last_response.should be_ok
    last_response.body.should == "nochg 2001:db8::1\ngood 2001:db8::1"
  end

  it 'uses clients remote IP address if myip not specified' do
    authorize 'test', 'secret'
    get '/nic/update?hostname=foo.example.org'
    last_response.should be_ok
    last_response.body.should == 'good 127.0.0.1'
  end
end
