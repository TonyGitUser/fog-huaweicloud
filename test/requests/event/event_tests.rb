require "test_helper"

describe "Fog::Event[:huaweicloud] | event requests" do
  before do
    @metering = Fog::Event::HuaweiCloud.new
    @event_format = {
      'message_id' => String,
      'event_type' => String
    }
  end

  describe "success" do
    it "#list_events" do
      @metering.list_events.body.
        must_match_schema([@event_format])
    end

    it "#get_event" do
      @metering.get_event('test').body.
        must_match_schema(@event_format)
    end
  end
end
