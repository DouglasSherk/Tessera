class UsersController < ApplicationController
  include PolygonAuth

  def redirectIfLoggedIn
    if session.has_key?(:loggedin)
      redirect_to users_url
      return true
    end

    return false
  end

  def redirectIfNotLoggedIn
    if !session.has_key?(:loggedin)
      redirect_to :action => "login", :notice => 'You must login to view this page.'
      return true
    end

    return false
  end

  def createNewPattern
    storeVerticesInSession(false) # don't force
    @vertices = session[:vertices]
    @firstVertex = session[:firstVertex]
    @security = session[:security]
  end


  def storeVerticesInSession(force)
    session[:security] ||= 0
    auth = PolygonAuth::PolygonGenerator.new

    if force
      session[:vertices] = auth.generatePolygon(session[:security])
      session[:firstVertex] = auth.generateFirstVertex(session[:vertices])
    else
      session[:vertices] ||= auth.generatePolygon
      session[:firstVertex] ||= auth.generateFirstVertex(session[:vertices])
    end
  end

  def convertPatternToLogicalForm
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

    return validation, logicalPattern
  end

  # GET /users
  # GET /users.json
  def index
    @loggedin = session[:loggedin]

    respond_to do |format|
      format.html # index.html.erb
      format.json { head :no_content }
    end
  end

  # GET /users/list
  # GET /users/list.json
  def list
    return if redirectIfNotLoggedIn

    @users = User.all

    respond_to do |format|
      format.html # list.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/login
  # GET /users/login.json
  def login
    return if redirectIfLoggedIn

    @user = User.new

    createNewPattern()

    session[:lastPageWithPolygon] = 'login'

    respond_to do |format|
      format.html # login.html.erb
      format.json { head :no_content }
    end
  end

  # POST /users/loggedin
  # POST /users/loggedin.json
  def loggedin
    return if redirectIfLoggedIn

    @users = User.all
    encrypt = PolygonAuth::PolygonEncrypt.new

    validation, logicalPattern = convertPatternToLogicalForm()

    foundValidPattern = false
    @users.each do |user|
      if user[:name] == @user[:name]
        password = encrypt.passwordFromHash(user[:password])
        if password == logicalPattern.to_json
          @user = user
          foundValidPattern = true
          break
        end
      end
    end

    respond_to do |format|
      if !validation.empty?
        format.html { redirect_to :action => "login", :notice => validation }
        format.json { head :no_content }
      elsif foundValidPattern
        session[:loggedin] = true
        storeVerticesInSession(true) # force
        format.html { redirect_to :action => "index", :notice => 'You are now logged in as "' + @user.name + '"' }
        format.json { head :no_content }
      else
        format.html { redirect_to :action => "login", :notice => 'Given name/pattern combination not found.'}
        format.json { head :no_content }
      end
    end
  end

  # GET /users/logout
  # GET /users/logout.json
  def logout
    return if redirectIfNotLoggedIn

    reset_session

    storeVerticesInSession(true) # force

    respond_to do |format|
      format.html { redirect_to :action => "index" }
      format.json { head :no_content }
    end
  end

  # GET /users/refresh
  # GET /users/refresh.json
  def refresh
    session[:security] = params[:security].to_i

    storeVerticesInSession(true) # force

    respond_to do |format|
      format.html { redirect_to :action => session[:lastPageWithPolygon] || 'new' }
      format.json { head :no_content }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    return if redirectIfLoggedIn

    @user = User.new

    createNewPattern()

    session[:lastPageWithPolygon] = 'new'

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # POST /users/create
  # POST /users/create.json
  def create
    return if redirectIfLoggedIn

    encrypt = PolygonAuth::PolygonEncrypt.new

    validation, logicalPattern = convertPatternToLogicalForm()

    respond_to do |format|
      if !validation.empty?
        format.html { redirect_to :action => "new", notice: validation }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      else
        @user.password = encrypt.encryptPattern(logicalPattern)
        if @user.save
          storeVerticesInSession(true) # force
          format.html { redirect_to :action => "new", notice: 'User was successfully created.' }
          format.json { render json: @user, status: :created, location: @user }
        else
          format.html { render action: "new" }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end

      storeVerticesInSession(true) # force
    end
  end

  ###################
  # DELETED METHODS #
  ###################

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

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
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
