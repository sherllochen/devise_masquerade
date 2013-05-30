require 'spec_helper'

describe DashboardController do
  shared_examples_for '#masquerade' do
    context 'when logged in' do
      before { logged_in }

      context 'and admin masquerade by user' do
        let!(:user) { create(model_name) }

        before do
          user.masquerade!

          get :index, :masquerade => user.masquerade_key
        end

        it { current_user.reload.should == user }
      end
    end
  end

  context 'with different models' do
    describe 'user' do
      let(:model_name) { :user }

      it_should_behave_like '#masquerade'
    end

    describe 'admin' do
      let(:model_name) { :admin }

      it_should_behave_like '#masquerade'
    end
  end
end

