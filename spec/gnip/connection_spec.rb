require File.dirname(__FILE__) + '/../spec_helper'

describe Gnip::Connection do


    before do
        @mock_publisher_name = 'mock_pub'
        @mock_filter_name = 'mock_filter'
        @mock_publisher = Gnip::Publisher.new(@mock_publisher_name)
        @mock_filter = Gnip::Filter.new(@mock_filter_name)

        @server_now = Time.now.utc
        @activities = pub_activities
        @gnip_config = Gnip::Config.new("user", "password", "s.gnipcentral.com", false)
        @gnip_connection = Gnip::Connection.new(@gnip_config)
    end

    describe "Reqest Header" do
        it "should include an agent string header" do
            header = @gnip_connection.send(:headers)
            header['User-Agent'].should == "Gnip-Client-Ruby/2.0.4"
        end

        it "should include authorization header" do
            header = @gnip_connection.send(:headers)
            header['Authorization'].should ==  'Basic ' + Base64::encode64("#{@gnip_config.user}:#{@gnip_config.password}")
        end

        it 'should include content type header' do
            header = @gnip_connection.send(:headers)
            header['Content-Type'].should == 'application/xml'
        end

        it "should include gzip header if configured for gzip" do
            gnip_config = Gnip::Config.new("user", "password", "s.gnipcentral.com", true)
            gnip_connection = Gnip::Connection.new(gnip_config)
            header = gnip_connection.send(:headers)
            header['Content-Encoding'].should == 'gzip'
            header['Accept-Encoding'].should == 'gzip'
        end

        it "should include gzip header if configured for gzip" do
            header = @gnip_connection.send(:headers)
            header['Content-Encoding'].should == nil
            header['Accept-Encoding'].should == nil
        end
    end

    describe "Notifictaion Streams For Subscriber" do
        it "should get activities per publisher for a given time" do
            setup_mock_notification_for_publisher( @activities, @server_now)
            response, activities = @gnip_connection.publisher_notifications_stream(@mock_publisher, @server_now)
            response.code.should == '200'
            Gnip::Activity.list_to_xml(activities).should == @activities
        end

        it "should get current activites  per publisher " do
            setup_mock_notification_for_publisher(@activities)
            response, activities = @gnip_connection.publisher_notifications_stream(@mock_publisher)
            response.code.should == '200'
            Gnip::Activity.list_to_xml(activities).should == @activities
        end

        it "should get activities per filter for a given time" do
            setup_mock_notification_for_filter(@activities, @server_now)
            response, activities = @gnip_connection.filter_notifications_stream(@mock_publisher, @mock_filter, @server_now)
            response.code.should == '200'
            Gnip::Activity.list_to_xml(activities).should == @activities
        end

        it "should get current activites per filter" do
            setup_mock_notification_for_filter(@activities)
            response, activities = @gnip_connection.filter_notifications_stream(@mock_publisher, @mock_filter)
            response.code.should == '200'
            Gnip::Activity.list_to_xml(activities).should == @activities
        end
    end

    describe "ActivityStream" do

        describe "For Subscriber" do
            it "should get activities per publisher for a given time" do
                setup_mock_for_publisher( @activities, @server_now)
                response, activities = @gnip_connection.publisher_activities_stream(@mock_publisher, @server_now)
                response.code.should == '200'
                Gnip::Activity.list_to_xml(activities).should == @activities
            end

            it "should get current activites  per publisher " do
                setup_mock_for_publisher(@activities)
                response, activities = @gnip_connection.publisher_activities_stream(@mock_publisher)
                response.code.should == '200'
                Gnip::Activity.list_to_xml(activities).should == @activities
            end

            it "should get activities per filter for a given time" do
                setup_mock_for_filter(@activities, @server_now)
                response, activities = @gnip_connection.filter_activities_stream(@mock_publisher, @mock_filter, @server_now)
                response.code.should == '200'
                Gnip::Activity.list_to_xml(activities).should == @activities
            end

            it "should get current activites per filter" do
                setup_mock_for_filter(@activities)
                response, activities = @gnip_connection.filter_activities_stream(@mock_publisher, @mock_filter)
                response.code.should == '200'
                Gnip::Activity.list_to_xml(activities).should == @activities
            end
        end

        describe "For Publisher" do
            it "should post activities as xml successfully" do
                setup_mock_for_publishing(@activities)
                response = @gnip_connection.publish_xml(@mock_publisher, @activities)
                response.code.should == "200"
            end

            it "should post activities as list successfully" do
                now = Time.now
                activity_list = []
                activity_list << Gnip::Activity.new("joe", "added_friend", now, "qwerty890")
                activity_list << Gnip::Activity.new("jane", "added_application", now, "def456")
                setup_mock_for_publishing(pub_activities_at(now))
                response = @gnip_connection.publish(@mock_publisher, activity_list)
                response.code.should == "200"
            end
        end

        it 'should marshall to a list correctly' do
            now = Time.now
            activity_xml =  pub_activities_at(now)
            activity_list = Gnip::Activity.list_from_xml(activity_xml)
            activity = activity_list[0]
            activity.at.should == now.xmlschema
            activity.actor.should == 'joe'
            activity.action.should == 'added_friend'
            activity.url.should == 'qwerty890'
            activity = activity_list[1]
            activity.at.should == now.xmlschema
            activity.actor.should == 'jane'
            activity.action.should == 'added_application'
            activity.url.should == 'def456'
        end

    end

    describe "Filter" do
        it "should create a new filter for given filter xml" do
            filter = Gnip::Filter.new('new-filter')
            setup_mock_for_filter_create(filter)
            response = @gnip_connection.create_filter(@mock_publisher, filter)
            response.code.should == "200"
        end

        it "should find a filter for given name" do
            filter_name = 'some-existing-filter'
            setup_mock_for_filter_find(filter_name)
            response, filter = @gnip_connection.get_filter(@mock_publisher, filter_name)
            response.code.should == "200"
            filter.name.should == 'some-existing-filter'
        end

        it "should update a filter for given filter" do
            filter = Gnip::Filter.new('existing-filter')
            setup_mock_for_filter_update(filter)
            response = @gnip_connection.update_filter(@mock_publisher, filter)
            response.code.should == "200"
        end

        it 'should add a rule to the given filter' do
            filter = Gnip::Filter.new('existing-filter')
            rule = Gnip::Rule.new('actor', 'testActor')
            setup_mock_for_add_rule(filter, rule)
            response = @gnip_connection.add_rule(@mock_publisher, filter, rule)
            response.code.should == "200"
        end

        it 'should remove a rule from the given filter' do
            filter = Gnip::Filter.new('existing-filter')
            rule = Gnip::Rule.new('actor', 'testUid')
            setup_mock_for_delete_rule(filter, rule)
            response = @gnip_connection.remove_rule(@mock_publisher, filter, rule)
            response.code.should == "200"
        end

        it "should delete a filter for given filter" do
            filter = Gnip::Filter.new('existing-filter')
            setup_mock_for_filter_delete(filter)
            response = @gnip_connection.remove_filter(@mock_publisher, filter)
            response.code.should == "200"
        end
    end

    describe "Publisher" do

        it "should create a new publisher" do
            publisher = Gnip::Publisher.new('new-publisher')
            setup_mock_for_publisher_create(publisher)
            response = @gnip_connection.create_publisher(publisher)
            response.code.should == "200"
        end

        it "should return a  publisher for given publisher name" do
            publisher_name = 'existing-publsher'
            setup_mock_for_publisher_get(publisher_name)
            response, publisher = @gnip_connection.get_publisher(publisher_name)
            response.code.should == "200"
            publisher.name.should == publisher_name
        end
    end

    describe "Publihsers" do
        it 'should list existing publishers' do
            setup_mock_for_publishers_get([@mock_publisher])
            response, publishers = @gnip_connection.get_publishers
            response.code.should == "200"
            publishers.include?(@mock_publisher).should be_true
        end
    end

    private

    def mock_http
        a_mock = mock('http_mock')
        Net::HTTP.should_receive(:new).with(@gnip_config.base_url, 443).and_return(a_mock)
        a_mock.should_receive(:use_ssl=).with(true)
        a_mock.should_receive(:read_timeout=).with(5)
        a_mock
    end

    def headers
        @gnip_connection.send(:headers)
    end

    def successful_response
        response = mock('response')
        response.should_receive(:code).with(no_args).any_number_of_times.and_return("200")
        response.should_receive(:[]).with('Content-Encoding').any_number_of_times.and_return('')
        response
    end

    def setup_mock_for_publishers_get(expected_publishers)
        mock_response = successful_response
        mock_response.should_receive(:body).with(no_args).and_return(list_to_xml(expected_publishers, 'publishers'))
        mock_http.should_receive(:get2).with("/publishers.xml", headers).and_return(mock_response)
    end

    def setup_mock_for_publisher_get(expected_publisher_name)
        mock_response = successful_response
        mock_response.should_receive(:body).with(no_args).and_return(Gnip::Publisher.new(expected_publisher_name).to_xml)
        mock_http.should_receive(:get2).with("/publishers/#{expected_publisher_name}.xml", headers).and_return(mock_response)
    end

    def setup_mock_for_publisher_create(expected_publisher)
        mock_http.should_receive(:post2).with("/publishers", expected_publisher.to_xml, headers).and_return(successful_response)
    end

    def setup_mock_for_filter_create(expected_filter)
        mock_http.should_receive(:post2).with("/publishers/#{@mock_publisher_name}/filters", expected_filter.to_xml, headers).and_return(successful_response)
    end

    def setup_mock_for_add_rule(filter, rule)
        mock_http.should_receive(:post2).with("/publishers/#{@mock_publisher_name}/filters/#{filter.name}/rules.xml", rule.to_xml, headers).and_return(successful_response)
    end

    def setup_mock_for_delete_rule(filter, rule)
        mock_http.should_receive(:delete).with("/publishers/#{@mock_publisher_name}/filters/#{filter.name}/rules?type=#{rule.type}&value=#{rule.value}", headers).and_return(successful_response)
    end

    def setup_mock_for_filter_update(expected_filter)
        mock_http.should_receive(:put2).with("/publishers/#{@mock_publisher_name}/filters/#{expected_filter.name}.xml", expected_filter.to_xml, headers).and_return(successful_response)
    end

    def setup_mock_for_filter_delete(expected_filter)
        mock_http.should_receive(:delete).with("/publishers/#{@mock_publisher_name}/filters/#{expected_filter.name}.xml", headers).and_return(successful_response)
    end

    def setup_mock_for_filter_find(expected_filter_name)
        mock_response = successful_response
        mock_response.should_receive(:body).with(no_args).and_return(Gnip::Filter.new(expected_filter_name).to_xml)
        mock_http.should_receive(:get2).with("/publishers/#{@mock_publisher_name}/filters/#{expected_filter_name}.xml", headers).and_return(mock_response)
    end

    def setup_mock_for_publishing(activities_xml)
        mock_http.should_receive(:post2).with("/publishers/#{@mock_publisher_name}/activity.xml", activities_xml, headers).and_return(successful_response)
    end

    def setup_mock_for_publisher(activities, server_time = nil)
        prefix_path = "/publishers/#{@mock_publisher_name}"
        setup_mock_for_activity_get(activities, prefix_path, server_time)
    end

    def setup_mock_notification_for_publisher(activities, server_time = nil)
        prefix_path = "/publishers/#{@mock_publisher_name}"
        setup_mock_for_notification_get(activities, prefix_path, server_time)
    end

    def setup_mock_for_activity_get(activities, prefix_path, server_time = nil)
        headers = @gnip_connection.send(:headers)
        path =
                if (server_time)
                    "#{prefix_path}/activity/#{server_time.to_gnip_bucket_id}.xml"
                else
                    "#{prefix_path}/activity/current.xml"
                end
        mock_response = successful_response
        mock_response.should_receive(:body).and_return(activities)
        mock_http.should_receive(:get2).with(path, headers).and_return(mock_response)
    end

    def setup_mock_for_notification_get(activities, prefix_path, server_time = nil)
        headers = @gnip_connection.send(:headers)
        path =
                if (server_time)
                    "#{prefix_path}/notification/#{server_time.to_gnip_bucket_id}.xml"
                else
                    "#{prefix_path}/notification/current.xml"
                end
        mock_response = successful_response
        mock_response.should_receive(:body).and_return(activities)
        mock_http.should_receive(:get2).with(path, headers).and_return(mock_response)
    end

    def setup_mock_for_filter(activities, server_time = nil)
        prefix_path = "/publishers/#{@mock_publisher_name}/filters/#{@mock_filter_name}"
        setup_mock_for_activity_get(activities, prefix_path, server_time)
    end

    def setup_mock_notification_for_filter(activities, server_time = nil)
        prefix_path = "/publishers/#{@mock_publisher_name}/filters/#{@mock_filter_name}"
        setup_mock_for_notification_get(activities, prefix_path, server_time)
    end

    def pub_activities_at(time)
        str = <<-HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity actor="joe" url="qwerty890" action="added_friend" at="#{time.xmlschema}" />
    <activity actor="jane" url="def456" action="added_application" at="#{time.xmlschema}" />
</activities>
        HEREDOC
        str
    end

    def pub_activities
        str = <<-HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<activities>
    <activity actor="joe" url="qwerty890" action="added_friend" at="2007-05-23T00:53:11+01:00" />
    <activity actor="jane" url="def456" action="added_application" at="2008-05-23T00:52:11+04:00" />
</activities>
        HEREDOC
        str
    end

    def list_to_xml(list, root_name)
        list = [] if list.nil?
        return XmlSimple.xml_out(list.collect { |item| item.to_hash}, {'RootName' => root_name, 'AnonymousTag' => nil, 'XmlDeclaration' => Gnip.header_xml})
    end
end
