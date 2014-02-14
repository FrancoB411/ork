require_relative '../helper'

Protest.describe 'collection' do
  class Post
    include Ork::Document
    attribute :name

    collection :comments, :Comment
    collection :weird_comments, :Comment, :weird_post
  end

  class Comment
    include Ork::Document
    attribute :text

    reference :post, :Post
    reference :weird_post, :Post
  end

  setup do
    randomize_bucket_name Post
    randomize_bucket_name Comment
  end

  test 'return an empty array when there are not referenced objects' do
    post = Post.new

    assert post.comments.empty?
  end

  test 'defines reader method but not a writer method' do
    post = Post.new

    assert post.respond_to?(:comments_add)
    assert post.respond_to?(:comments_ids)
    assert post.respond_to?(:comments_ids=)
    assert post.respond_to?(:comments)
    deny   post.respond_to?(:comments=)
  end

  test 'raise an exception assigning an object of the wrong type' do
    assert_raise(Ork::InvalidClass) do
      Post.new.comments_add 'Not a comment'
    end
  end

  test 'return the array of Comments assigned to this Post' do
    post = Post.create name: 'New'
    comment1 = Comment.create text: 'one'
    comment2 = Comment.create text: 'two'

    post.comments_add comment1
    post.comments_add comment2
    comment1.reload
    comment2.reload

    deny   comment1.post
    deny   comment2.post
    deny   post.comments.empty?
    assert post.comments_ids.include?(comment1.id)
    assert post.comments_ids.include?(comment2.id)
    assert post.comments.include?(comment1)
    assert post.comments.include?(comment2)
  end

  test 'object reference with not default key' do
    post = Post.create name: 'New'
    comment1 = Comment.create text: 'one'
    comment2 = Comment.create text: 'two'

    post.weird_comments_add comment1
    post.weird_comments_add comment2
    comment1.reload
    comment2.reload

    deny   comment1.post
    deny   comment2.post
    deny   post.weird_comments.empty?
    assert post.weird_comments_ids.include?(comment1.id)
    assert post.weird_comments_ids.include?(comment2.id)
    assert post.weird_comments.include?(comment1)
    assert post.weird_comments.include?(comment2)
  end

  test 'update referenced object will not update the collection' do
    post = Post.create name: 'New'
    comment = Comment.create text: 'First One'

    assert post.comments.empty?

    comment.post = post
    comment.save
    post.reload

    assert post.comments.empty?
  end

  test 'massive association for child objects (using ids)' do
    comment1 = Comment.create text: 'First'
    comment2 = Comment.create text: 'Second'
    post = Post.create name: 'Massive', comments_ids: [comment1.id, comment2.id]

    deny   post.comments.empty?
    assert post.comments.include?(comment1)
    assert post.comments.include?(comment2)

    post.comments_ids = [comment1.id]

    deny   post.comments.empty?
    assert post.comments.include?(comment1)
    deny   post.comments.include?(comment2)
  end
end

