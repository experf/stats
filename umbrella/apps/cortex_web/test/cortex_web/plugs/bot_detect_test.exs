defmodule CortexWeb.BotDetectTest do
  use ExUnit.Case

  alias CortexWeb.BotDetect

  describe "load_crawlers/0" do
    test "loads crawlers!" do
      crawlers = BotDetect.load_crawlers()

      assert is_list(crawlers)
      assert length(crawlers) > 0
    end
  end

  describe "match_crawlers/2" do
    test "matches LinkedInBot" do
      user_agent = "LinkedInBot/1.0 (compatible; Mozilla/5.0; Apache-HttpClient +http://www.linkedin.com)"
      crawlers = BotDetect.load_crawlers()

      matches = BotDetect.match_crawlers(crawlers, user_agent)
      assert length(matches) == 1

      match = matches |> List.first()
      assert match["pattern"] == "LinkedInBot"
    end
  end
end
