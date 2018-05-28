class Api::V1::UsersController < Api::V1::ApiController
  before_action :doorkeeper_authorize!

  def index
    render json: User.all.includes(:roles, :groups), root_url: root_url, status: 200
  end

  def show
    @user = User.find(params[:id])
    render json: @user, serializer: SingleUserSerializer, root_url: root_url, status: 200
  end

end
