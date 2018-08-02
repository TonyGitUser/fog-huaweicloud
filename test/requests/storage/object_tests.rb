require "test_helper"

def test_temp_url(url_s, time, desired_scheme)
  object_url = URI.parse(url_s)
  query_params = URI.decode_www_form(object_url.query)
  object_url.scheme.must_equal desired_scheme
  object_url.path.must_match %r{/#{@directory.identity}/fog_object}
  query_params.any? { |p| p[0] == 'temp_url_sig' }.must_equal true
  query_params.any? { |p| p == ['temp_url_expires', time.to_i.to_s] }.must_equal true
end

describe "Fog::Storage[:huaweicloud] | object requests" do
  before do
    unless Fog.mocking?
      @directory = Fog::Storage[:huaweicloud].directories.create(:key => 'fogobjecttests')
    end

    module HuaweiCloudStorageHelpers
      def override_path(path)
        @path = path
      end
    end
  end

  after do
    unless Fog.mocking?
      @directory.files.each(&:destroy)
      @directory.destroy
    end
  end

  describe "success" do
    it "#put_object('fogobjecttests', 'fog_object')" do
      resp = Fog::Storage[:huaweicloud].put_object('fogobjecttests', 'fog_object', lorem_file)
      resp.headers['ETag'].must_equal '80d7930fe13ff4e45156b6581656a247'
    end

    describe "with_object" do
      before do
        file = lorem_file
        resp = Fog::Storage[:huaweicloud].put_object('fogobjecttests', 'fog_object', file)
        file.close
        resp.headers['ETag'].must_equal '80d7930fe13ff4e45156b6581656a247'
      end

      it "#get_object('fogobjectests', 'fog_object')" do
        unless Fog.mocking?
          resp = Fog::Storage[:huaweicloud].get_object('fogobjecttests', 'fog_object')
          resp.body.must_equal lorem_file.read
        end
      end

      it "#get_object('fogobjecttests', 'fog_object', &block)" do
        unless Fog.mocking?
          data = ''
          Fog::Storage[:huaweicloud].get_object('fogobjecttests', 'fog_object') do |chunk, _remaining_bytes, _total_bytes|
            data << chunk
          end
          data.must_equal lorem_file.read
        end
      end

      it "#public_url('fogobjectests', 'fog_object')" do
        unless Fog.mocking?
          url = Fog::Storage[:huaweicloud].directories.first.files.first.public_url
          url.end_with?('/fogobjecttests/fog_object').must_equal true
        end
      end

      it "#public_url('fogobjectests')" do
        unless Fog.mocking?
          url = Fog::Storage[:huaweicloud].directories.first.public_url
          url.end_with?('/fogobjecttests').must_equal true
        end
      end

      it "#head_object('fogobjectests', 'fog_object')" do
        unless Fog.mocking?
          resp = Fog::Storage[:huaweicloud].head_object('fogobjecttests', 'fog_object')
          resp.headers['ETag'].must_equal '80d7930fe13ff4e45156b6581656a247'
        end
      end

      it "#post_object('fogobjecttests', 'fog_object')" do
        unless Fog.mocking?
          Fog::Storage[:huaweicloud].post_object(
            'fogobjecttests',
            'fog_object',
            'X-Object-Meta-test-header' => 'fog-test-value'
          )
          resp = Fog::Storage[:huaweicloud].head_object('fogobjecttests', 'fog_object')
          resp.headers.must_include 'X-Object-Meta-Test-Header'
          resp.headers['X-Object-Meta-Test-Header'].must_equal 'fog-test-value'
        end
      end

      it "#delete_object('fogobjecttests', 'fog_object')" do
        unless Fog.mocking?
          resp = Fog::Storage[:huaweicloud].delete_object('fogobjecttests', 'fog_object')
          resp.status.must_equal 204
        end
      end

      it "#get_object_http_url('directory.identity', 'fog_object', expiration timestamp)" do
        unless Fog.mocking?
          ts = Time.at(1_395_343_213)
          url_s = Fog::Storage[:huaweicloud].get_object_http_url(@directory.identity, 'fog_object', ts)
          test_temp_url(url_s, ts, 'http')
        end
      end

      it "#get_object_https_url('directory.identity', 'fog_object', expiration timestamp)" do
        unless Fog.mocking?
          ts = Time.at(1_395_343_213)
          url_s = Fog::Storage[:huaweicloud].get_object_https_url(@directory.identity, 'fog_object', ts)
          test_temp_url(url_s, ts, 'https')
        end
      end

      it "#get_object_https_url_numeric('directory.identity', 'fog_object', expiration_timestamp)" do
        unless Fog.mocking?
          ts = Time.at(1_500_000_000)
          fog = Fog::Storage.new(:provider => :huaweicloud, :huaweicloud_temp_url_key => '12345')
          url_s = fog.get_object_https_url(@directory.identity, 'fog_object', ts)
          test_temp_url(url_s, ts, 'https')
        end
      end
    end

    describe "put_object with block" do
      it "#put_object('fogobjecttests', 'fog_object', &block)" do
        begin
          file = lorem_file
          buffer_size = file.stat.size / 2 # chop it up into two buffers
          resp = Fog::Storage[:huaweicloud].put_object('fogobjecttests', 'fog_block_object', nil) do
            file.read(buffer_size).to_s
          end
        ensure
          file.close
        end
        resp.headers['ETag'].must_equal '80d7930fe13ff4e45156b6581656a247'
      end

      describe "with_object" do
        before do
          file = lorem_file
          Fog::Storage[:huaweicloud].put_object('fogobjecttests', 'fog_block_object', nil) do
            file.read(file.stat.size).to_s
          end
          file.close
        end

        it "#get_object" do
          unless Fog.mocking?
            resp = Fog::Storage[:huaweicloud].get_object('fogobjecttests', 'fog_block_object')
            resp.body.must_equal lorem_file.read
          end
        end

        it "#delete_object" do
          unless Fog.mocking?
            resp = Fog::Storage[:huaweicloud].delete_object('fogobjecttests', 'fog_block_object')
            resp.status.must_equal 204
          end
        end
      end
    end

    describe "deletes multiple objects" do
      before do
        unless Fog.mocking?
          Fog::Storage[:huaweicloud].put_object('fogobjecttests', 'fog_object', lorem_file)
          Fog::Storage[:huaweicloud].put_object('fogobjecttests', 'fog_object2', lorem_file)
          Fog::Storage[:huaweicloud].directories.create(:key => 'fogobjecttests2')
          Fog::Storage[:huaweicloud].put_object('fogobjecttests2', 'fog_object', lorem_file)
        end

        @expected = {
          "Number Not Found" => 0,
          "Response Status"  => "200 OK",
          "Errors"           => [],
          "Number Deleted"   => 2,
          "Response Body"    => ""
        }
      end

      after do
        unless Fog.mocking?
          dir2 = Fog::Storage[:huaweicloud].directories.get('fogobjecttests2')
          unless dir2.nil?
            dir2.files.each(&:destroy)
            dir2.destroy
          end
        end
      end

      it "#delete_multiple_objects" do
        unless Fog.mocking?
          resp = Fog::Storage[:huaweicloud].delete_multiple_objects(
            'fogobjecttests', %w[fog_object fog_object2]
          )
          resp.body.must_equal @expected
        end
      end

      it "deletes object and container" do
        unless Fog.mocking?
          resp = Fog::Storage[:huaweicloud].delete_multiple_objects(
            nil,
            ['fogobjecttests2/fog_object', 'fogobjecttests2']
          )
          resp.body.must_equal @expected
        end
      end
    end
  end

  describe "failure" do
    it "#get_object('fogobjecttests', 'fog_non_object')" do
      unless Fog.mocking?
        proc do
          Fog::Storage[:huaweicloud].get_object('fogobjecttests', 'fog_non_object')
        end.must_raise(Fog::Storage::HuaweiCloud::NotFound)
      end
    end

    it "#get_object('fognoncontainer', 'fog_non_object')" do
      unless Fog.mocking?
        proc do
          Fog::Storage[:huaweicloud].get_object('fognoncontainer', 'fog_non_object')
        end.must_raise(Fog::Storage::HuaweiCloud::NotFound)
      end
    end

    it "#head_object('fogobjecttests', 'fog_non_object')" do
      unless Fog.mocking?
        proc do
          Fog::Storage[:huaweicloud].head_object('fogobjecttests', 'fog_non_object')
        end.must_raise(Fog::Storage::HuaweiCloud::NotFound)
      end
    end

    it "#head_object('fognoncontainer', 'fog_non_object')" do
      unless Fog.mocking?
        proc do
          Fog::Storage[:huaweicloud].head_object('fognoncontainer', 'fog_non_object')
        end.must_raise(Fog::Storage::HuaweiCloud::NotFound)
      end
    end

    it "#post_object('fognoncontainer', 'fog_non_object')" do
      unless Fog.mocking?
        proc do
          Fog::Storage[:huaweicloud].post_object('fognoncontainer', 'fog_non_object')
        end.must_raise(Fog::Storage::HuaweiCloud::NotFound)
      end
    end

    it "#delete_object('fogobjecttests', 'fog_non_object')" do
      unless Fog.mocking?
        proc do
          Fog::Storage[:huaweicloud].delete_object('fogobjecttests', 'fog_non_object')
        end.must_raise(Fog::Storage::HuaweiCloud::NotFound)
      end
    end

    it "#delete_object('fognoncontainer', 'fog_non_object')" do
      unless Fog.mocking?
        proc do
          Fog::Storage[:huaweicloud].delete_object('fognoncontainer', 'fog_non_object')
        end.must_raise(Fog::Storage::HuaweiCloud::NotFound)
      end
    end

    describe "#delete_multiple_objects" do
      before do
        unless Fog.mocking?
          @expected = {
            "Number Not Found" => 2,
            "Response Status"  => "200 OK",
            "Errors"           => [],
            "Number Deleted"   => 0,
            "Response Body"    => ""
          }
        end
      end

      it "reports missing objects" do
        unless Fog.mocking?
          resp = Fog::Storage[:huaweicloud].delete_multiple_objects(
            'fogobjecttests', %w[fog_non_object fog_non_object2]
          )
          resp.body.must_equal @expected
        end
      end

      it "reports missing container" do
        unless Fog.mocking?
          resp = Fog::Storage[:huaweicloud].delete_multiple_objects(
            'fognoncontainer', %w[fog_non_object fog_non_object2]
          )
          resp.body.must_equal @expected
        end
      end

      it "deleting non-empty container" do
        unless Fog.mocking?
          file = lorem_file
          resp = Fog::Storage[:huaweicloud].put_object('fogobjecttests', 'fog_object', file)
          file.close
          resp.headers['ETag'].must_equal '80d7930fe13ff4e45156b6581656a247'

          expected = {
            "Number Not Found" => 0,
            "Response Status"  => "400 Bad Request",
            "Errors"           => [['fogobjecttests', '409 Conflict']],
            "Number Deleted"   => 0,
            "Response Body"    => ""
          }

          resp = Fog::Storage[:huaweicloud].delete_multiple_objects(
            nil,
            %w[fogobjecttests]
          )
          resp.body.must_equal expected
        end
      end
    end
  end
end
