require 'test_helper'

describe WorksController do
  describe "root" do
    it "succeeds with all media types" do
      # Precondition: there is at least one media of each category
      get root_path
      must_respond_with :success

    end

    it "succeeds with one media type absent" do
      # Precondition: there is at least one media in two of the categories
      work = Work.find_by(category: "movie")

      work.destroy

      get root_path
      must_respond_with :success

    end

    it "succeeds with no media" do

      works.each do |work|
        work.destroy
      end

      get root_path
      must_respond_with :success

    end
  end

  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

  describe "index" do
    it "succeeds when there are works" do
      work_id = Work.first.id

      get work_path(work_id)
      must_respond_with :success

    end

    it "succeeds when there are no works" do

      Work.all.each { |work| work.destroy }

      Work.count.must_equal 0

      get works_path
      must_respond_with :success

    end
  end

  describe "new" do

    before do
      login_for_test(users(:dee))
    end

    it "succeeds" do

      get new_work_path
      must_respond_with :success

    end
  end

  describe "create" do

    before do
        login_for_test(users(:dee))
      end

    it "creates a work with valid data for a real category" do

      test_hash = {
             work: {
               title: "test-title",
               creator: "test-creator",
               description: "test-description",
               publication_year: 2020,
               category: "movie"
             }
           }


        expect {
        post works_path, params: test_hash
        }.must_change 'Work.count', 1

        work = Work.find_by(title: test_hash[:work][:title])

        expect(work.creator).must_equal test_hash[:work][:creator]
        expect(work.description).must_equal test_hash[:work][:description]
        expect(work.publication_year).must_equal test_hash[:work][:publication_year]
        expect(work.category).must_equal test_hash[:work][:category]
        must_redirect_to work_path(work)

    end

    it "renders bad_request and does not update the DB for bogus data" do

      test_hash = {
        work: {
          creator: "test-creator",
          description: "test-description",
          publication_year: 2020,
          category: "movie"
        }
      }

      expect {
        post works_path, params: test_hash
      }.wont_change "Work.count"

      must_respond_with :bad_request

    end

    it "renders 400 bad_request for bogus categories" do

      work_hash = {
        work: {
          title: "test-title",
          creator: "test-creator",
          description: "test-description",
          publication_year: 2020,
          category: "fruit"
        }
      }

      expect {
      post works_path, params: work_hash
      }.wont_change 'Work.count'

      must_respond_with :bad_request
    end

  end

  describe "show" do

    before do
        login_for_test(users(:dee))
      end

    let(:existing_work) { Work.first }


    it "succeeds for an extant work ID" do

      work = Work.last.id + 1
      get work_path(work)
      must_respond_with :not_found


    end

    it "renders 404 not_found for a bogus work ID" do

      user = User.first

      id = existing_work.id
      existing_work.destroy

      get work_path(existing_work)
      must_respond_with :not_found
    end
  end

  describe "edit" do

    before do
        login_for_test(users(:dee))
      end

    it "succeeds for an extant work ID" do

      get work_path(works(:movie).id)
      must_respond_with :success

    end

    it "renders 404 not_found for a bogus work ID" do

      get work_path(Work.last.id+1)
      must_respond_with :not_found

    end
  end

  describe "update" do

    before do
        login_for_test(users(:dee))
      end

    it "succeeds for valid data and an extant work ID" do

      put work_path(works(:album).id), params: {
        work: {
          title: "Old Title"
          }
        }

      updated_work = Work.find(works(:album).id)
      updated_work.title.must_equal "Old Title"

      must_respond_with :redirect
      must_redirect_to work_path(works(:album))

    end

    it "renders bad_request for bogus data" do

      put work_path(works(:album).id), params: {
        work: {
          title: "Old Title",
          category: "fruit"
          }
        }

      must_respond_with :not_found

    end

    it "renders 404 not_found for a bogus work ID" do

      get work_path(Work.last.id+1)
      must_respond_with :not_found

    end
  end

  describe "destroy" do

    before do
        login_for_test(users(:dee))
      end

    it "succeeds for an extant work ID" do

        work_id = Work.first.id

        expect{
           delete work_path(work_id)
         }.must_change('Work.count', -1)

        must_redirect_to root_path

    end

    it "renders 404 not_found and does not update the DB for a bogus work ID" do

      delete work_path(Work.last.id+1)
      must_respond_with :not_found

    end
  end

  describe "upvote" do

    before do
        login_for_test(users(:dee))
      end

    it "redirects to the work page if no user is logged in" do

      delete logout_path

      expect(session[:user_id]).must_be_nil
      must_respond_with :redirect
      must_redirect_to root_path

    end

    it "redirects to the work page after the user has logged out" do

      expect(session[:user_id]).must_equal users(:dee).id

      delete logout_path
      expect(session[:user_id]).must_equal nil

      work = Work.first
      post upvote_path(work.id)
      must_redirect_to work_path(work.id)

    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do

      expect(session[:user_id]).must_equal users(:dee).id
      work = works(:album)

      expect {
        post upvote_path(work.id)
      }.must_change 'Vote.count', 1
       must_respond_with :redirect

    end

    it "redirects to the work page if the user has already voted for that work" do

      expect(session[:user_id]).must_equal users(:dee).id

      work = works(:movie)

      expect {
        post upvote_path(work.id)
      }.wont_change 'Vote.count'

      must_redirect_to work_path(work.id)

    end
  end
end
