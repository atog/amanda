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
    assert first_key = store.keys("#{Amanda::Store::POST_KEY_PREFIX}*").first
    post = Amanda::Post.from_json(store.redis.get(first_key))
    assert_equal first_key, "#{Amanda::Store::POST_KEY_PREFIX}#{post.id}"
  end

  it "should return one post" do
    store = Amanda::Store.new("amanda_test.yml")
    store.store_posts_in_redis
    assert first_key = store.keys("#{Amanda::Store::POST_KEY_PREFIX}*").first
    assert store.post(first_key)
  end

  it "should return random post" do
    store = Amanda::Store.new("amanda_test.yml")
    store.store_posts_in_redis
    assert first_key = store.keys("#{Amanda::Store::POST_KEY_PREFIX}*").first
    assert store.random
  end

  it "should return all posts" do
    store = Amanda::Store.new("amanda_test.yml")
    store.store_posts_in_redis
    assert store.posts.any?
  end

  it "should return last post" do
    store = Amanda::Store.new("amanda_test.yml")
    store.store_posts_in_redis
    assert first_key = store.keys("#{Amanda::Store::POST_KEY_PREFIX}*").first
    assert store.last
  end

end