require 'test_helper'
require 'gds_api/postcode_sanitizer'

describe GdsApi::PostcodeSanitizer do

  describe "postcodes come through" do

    it "strips trailing spaces from entered postcodes" do
      assert_equal "WC2B 6NH", GdsApi::PostcodeSanitizer.sanitize("WC2B 6NH ")
    end

    it "strips non-alphanumerics from entered postcodes" do
      assert_equal "WC2B 6NH", GdsApi::PostcodeSanitizer.sanitize("WC2B   -6NH]")
    end

    it "transposes O/0 and I/1 if necessary" do
      # Thanks to the uk_postcode gem.
      assert_equal "W1A 0AA", GdsApi::PostcodeSanitizer.sanitize("WIA OAA")
    end

  end

end
