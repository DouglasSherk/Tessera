class UsersController < ApplicationController
  include PolygonAuth

  def createNewPattern
    storeVerticesInSession(false) # don't force
    @vertices = session[:vertices]
    @firstVertex = session[:firstVertex]
  end


  def storeVerticesInSession(force)
    auth = PolygonAuth::PolygonGenerator.new
    if force
      session[:vertices] = auth.generatePolygon(session[:security])
      session[:firstVertex] = auth.generateFirstVertex(session[:vertices])
    else
      session[:vertices] ||= auth.generatePolygon
      session[:firstVertex] ||= auth.generateFirstVertex(session[:vertices])
    end
  end

  # GET /users
  # GET /users.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { head :no_content }
    end
  end

  # GET /users/list
  # GET /users/list.json
  def list
    @users = User.all

    respond_to do |format|
      format.html # list.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/login
  # GET /users/login.json
  def login
    @user = User.new

    createNewPattern()

    respond_to do |format|
      format.html # login.html.erb
      format.json { head :no_content }
    end
  end

  # GET /users/refresh
  # GET /users/refresh.json
  def refresh
    session[:security] = params[:security].to_i

    storeVerticesInSession(true) # force

    respond_to do |format|
      format.html { redirect_to :action => "new" }
      format.json { head :no_content }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    createNewPattern()

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    encrypt = PolygonAuth::PolygonEncrypt.new
    pattern = JSON.parse(@user[:password])
    vertices = session[:vertices]
    firstVertex = session[:firstVertex]

    # Perform first-pass validation on pattern.
    validation = encrypt.validatePattern(vertices, pattern, session[:security])

    # Convert pattern to logical format.
    # XXX: We validate before this conversion, so any logic based on re-ordering
    #      needs to be done after here.
    auth = PolygonAuth::PolygonGenerator.new
    logicalPattern = auth.convertPatternToLogicalFormat(pattern, vertices, firstVertex)

    respond_to do |format|
      if !validation.empty?
        format.html { redirect_to :action => "new", notice: validation }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      else
        @user.password = encrypt.encryptPattern(logicalPattern)
        if @user.save
          format.html { redirect_to @user, notice: 'User was successfully created.' }
          format.json { render json: @user, status: :created, location: @user }
        else
          format.html { render action: "new" }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end

      storeVerticesInSession(true) # force
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
end
