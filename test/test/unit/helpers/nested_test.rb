require File.dirname(__FILE__)+'/../../test_helper'

class PostsControllerMock
  include ResourceController::Helpers
  extend ResourceController::Accessors
  class_reader_writer :belongs_to
end

class CommentsControllerMock
  include ResourceController::Helpers
  extend ResourceController::Accessors
  class_reader_writer :belongs_to
  belongs_to :post
end

class Helpers::NestedTest < Test::Unit::TestCase
  def setup
    @controller = PostsControllerMock.new

    @params = stub :[] => "1"
    @controller.stubs(:params).returns(@params)

    @object = Post.new
    Post.stubs(:find).with("1").returns(@object)
    
    @collection = mock()
    Post.stubs(:find).with(:all).returns(@collection)
  end
  
  context "parent type helper" do
    setup do
      @comments_controller = CommentsControllerMock.new
      @comment_params = stub()
      @comment_params.stubs(:[]).with(:post_id).returns 2
      
      @comments_controller.stubs(:params).returns(@comment_params)
    end

    should "get the params for the current parent" do
      assert_equal [:post], @comments_controller.send(:parent_types)
    end
    
    context "with multiple possible parents" do
      setup do
        CommentsControllerMock.class_eval do
          belongs_to :post, :product
        end
        
        @comment_params = stub()
        @comment_params.stubs(:[]).with(:product_id).returns 5
        @comment_params.stubs(:[]).with(:post_id).returns nil
        @comments_controller.stubs(:params).returns(@comment_params)
      end

      should "get the params for whatever models are available" do
        assert_equal [:product], @comments_controller.send(:parent_types)
      end
      
      teardown do
        CommentsControllerMock.class_eval do
          belongs_to :post
        end
      end
    end
    
    context "with multiple possible parents including deeply nested parent sets" do
      setup do
        CommentsControllerMock.class_eval do
          belongs_to :post, [:product, :tag]
        end
        
        @comment_params = stub()
        @comment_params.stubs(:[]).with(:post_id).returns nil
        @comment_params.stubs(:[]).with(:product_id).returns 5
        @comment_params.stubs(:[]).with(:tag_id).returns 5
        @comments_controller.stubs(:params).returns(@comment_params)
      end

      should "choose the matching set" do
        assert_equal [:product, :tag], @comments_controller.send(:parent_types)
      end
    end
    
    context "with no possible parent" do      
      should "return nil" do
        assert @controller.send(:parent_types).empty?, @controller.send(:parent_types).inspect
      end
    end
  end
  
  context "parent object helper" do
    setup do
      @comments_controller = CommentsControllerMock.new
      @comment_params = stub()
      @comment_params.stubs(:[]).with(:post_id).returns 2
      
      @comments_controller.stubs(:params).returns(@comment_params)
      @post = Post.new
      Post.stubs(:find).with(2).returns @post
    end

    should "return post with id 2" do
      assert_equal @post, @comments_controller.send(:parent_object)
    end
  end
end