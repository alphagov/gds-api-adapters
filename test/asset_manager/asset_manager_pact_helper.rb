module AssetManagerPactHelper
  include Pact::Helpers

  def a_multipart_request_body
    Pact.term(
      generate: construct_multipart_string([ASSET_DETAILS]),
      matcher: construct_multipart_regex([ASSET_DETAILS_REGEX]),
    )
  end

  def a_whitehall_multipart_request_body
    legacy_url_details = "\r\nContent-Disposition: form-data; name=\"asset[legacy_url_path]\"\r\n\r\n/government/uploads/some-edition/hello.txt\r\n"
    legacy_url_details_regex = /\s+Content-Disposition: form-data; name="asset\[legacy_url_path\]"\s+\/government\/uploads\/some-edition\/hello.txt\s+/
    Pact.term(
      generate: construct_multipart_string([ASSET_DETAILS, legacy_url_details]),
      matcher: construct_multipart_regex([ASSET_DETAILS_REGEX, legacy_url_details_regex]),
    )
  end

  def a_file_url_string
    Pact.term(
      generate: "http://static.dev.gov.uk/media/62b418d7c7d6b700ce9fa93d/hello.txt",
      matcher: /http:\/\/static.dev.gov.uk\/media\/\w{24}\/hello.txt/,
    )
  end

  def an_asset_id_string
    Pact.term(
      generate: "http://example.org/assets/4dca570c2975bc0d6d437491",
      matcher: /http:\/\/example.org\/assets\/\w{24}/,
    )
  end

  MULTIPART_HEADERS =
    { "Content-Type" => Pact.term(/multipart\/form-data/, "multipart/form-data; boundary=----RubyFormBoundaryjFAA2WBg0ki601kd") }.freeze
  JSON_CONTENT_TYPE = { "Content-Type" => "application/json; charset=utf-8" }.freeze
  ASSET_DETAILS = "\r\nContent-Disposition: form-data; name=\"asset[file]\"; filename=\"hello.txt\"\r\nContent-Type: text/plain\r\n\r\nHello, world!\n\r\n".freeze
  ASSET_DETAILS_REGEX = /\s+Content-Disposition: form-data; name="asset\[file\]"; filename="hello.txt"\s+Content-Type: text\/plain\s+Hello, world!\s+/.freeze

private

  def construct_multipart_string(multipart_contents)
    boundary = "------RubyFormBoundaryjFAA2WBg0ki601kd".freeze
    closing_string = "--\r\n"
    boundary + multipart_contents.join(boundary) + boundary + closing_string
  end

  def construct_multipart_regex(regexes)
    boundary_regex = /------RubyFormBoundary\w{16}/.source
    closing_regex =  /--\s+/.source
    Regexp.new(boundary_regex + regexes.map(&:source).join(boundary_regex) + boundary_regex + closing_regex)
  end
end
