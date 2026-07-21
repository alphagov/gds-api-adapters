require "test_helper"
require "gds_api/validators/base_path_validator"

describe GdsApi::Validators::BasePathValidator do
  let(:valid_path_examples) do
    [
      "/",
      "/government/topical-event/heat-wave-2026",
      "/government/topical-event/heat-wave-2026.csv",
      "#{'/0123456789' * 46}.jsonp",
    ]
  end

  let(:invalid_path_examples) do
    [
      nil,
      "government/topical-events",
      "//",
      "//govuk",
      "/Government/topical-events",
      "/government/topical_events",
      "/government/miss-ca$h",
      "/government/files,",
      "/government/files:-more-government/",
      "/values/../../secret-stuff",
      "/govermment/news/%0D%0A",
      "/govermment/news/%0d%0a",
      "/govermment/😊",
      "/gövernment/news",
      "#{'/0123456789' * 46}x.jsonp",
      "/government/news.",
    ]
  end

  let(:invalid_path_examples_errors) do
    [
      { base_path_invalid: ["Path cannot be nil"] },
      { base_path_invalid: ["Path must start with a /"] },
      { base_path_invalid: ["Path contains runs of . and or / characters, which could be penetration attempts"] },
      { base_path_invalid: ["Path contains runs of . and or / characters, which could be penetration attempts"] },
      { base_path_invalid: ["Path contains characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["Path contains characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["Path contains characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["Path contains characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["Path contains characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["Path contains runs of . and or / characters, which could be penetration attempts"] },
      { base_path_invalid: ["Path contains characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["Path contains characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["Path contains characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_invalid: ["Path contains characters that are not lowercase letters, numbers, -, ., or /"] },
      { base_path_too_long: ["Path cannot be longer than 512 characters"] },
      { base_path_invalid: ["Path cannot end with a ."] },
    ]
  end

  describe "#valid?" do
    it "returns true for valid paths" do
      valid_path_examples.each do |base_path|
        assert_equal(true, GdsApi::Validators::BasePathValidator.new(base_path).valid?, "#{base_path} should be accepted")
      end
    end

    it "returns false for valid paths" do
      invalid_path_examples.each do |base_path|
        assert_equal(false, GdsApi::Validators::BasePathValidator.new(base_path).valid?, "#{base_path} should not be accepted")
      end
    end
  end

  describe "#errors" do
    it "returns an empty hashs for valid paths" do
      valid_path_examples.each do |base_path|
        assert_equal({}, GdsApi::Validators::BasePathValidator.new(base_path).errors, "#{base_path} should not return errors")
      end
    end

    it "returns appropriate errors for valid paths" do
      invalid_path_examples.each_with_index do |base_path, idx|
        assert_equal(GdsApi::Validators::BasePathValidator.new(base_path).errors, invalid_path_examples_errors[idx], "#{base_path} should include errors")
      end
    end
  end
end
