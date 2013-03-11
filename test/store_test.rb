require "minitest/autorun"
require File.join(File.dirname(__FILE__), "..", "amanda")

describe Amanda::Store do

  it "should have a configured path" do
    assert Amanda::Store.new("amanda_test.yml").path
  end

  it "should read all posts" do
    store = Amanda::Store.new("amanda_test.yml")
    posts = store.read_posts_from_disk
    assert posts.size > 0
    assert Amanda::Post === posts.first
  end

  it "should store posts in redis" do
    store = Amanda::Store.new("amanda_test.yml")
    store.store_posts_in_redis
    assert first_key = store.redis.keys("post:*").first
    post = Amanda::Post.from_json(store.redis.get(first_key))
    assert_equal first_key, "post:#{post.id}"
  end
end