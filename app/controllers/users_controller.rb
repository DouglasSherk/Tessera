class UsersController < ApplicationController
  include PolygonAuth

  MAX_LOGINS = 3
  MAX_DOS = 10

  def redirectIfDOSingOrTooManyLogins
    if session.has_key?(:dos)
      render :dos
      return true
    elsif session.has_key?(:blocked)
      render :blocked
      return true
    end

    return false
  end

  def redirectIfLoggedIn
    if session.has_key?(:loggedin)
      redirect_to users_url
      return true
    end

    return false
  end

  def redirectIfNotLoggedIn
    if !session.has_key?(:loggedin)
      redirect_to :action => "login", :error => 'You must login to view this page.'
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

  def generateNewPatternIfNewPage(page)
    if session[:lastPageWithPolygon] != page
      storeVerticesInSession(true)
      createNewPattern()
    end

    session[:lastPageWithPolygon] = page
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
    return if redirectIfDOSingOrTooManyLogins

    @loggedin = session[:loggedin]

    respond_to do |format|
      format.html # index.html.erb
      format.json { head :no_content }
    end
  end

  # GET /users/list
  # GET /users/list.json
  def list
    return if redirectIfDOSingOrTooManyLogins
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
    return if redirectIfDOSingOrTooManyLogins
    return if redirectIfLoggedIn

    @user = User.new

    createNewPattern()

    generateNewPatternIfNewPage('login')

    respond_to do |format|
      format.html # login.html.erb
      format.json { head :no_content }
    end
  end

  # POST /users/loggedin
  # POST /users/loggedin.json
  def loggedin
    return if redirectIfDOSingOrTooManyLogins
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
        format.html { redirect_to :action => "login", :error => validation }
        format.json { head :no_content }
      elsif foundValidPattern
        session[:loggedin] = true
        storeVerticesInSession(true) # force
        format.html { redirect_to :action => "index", :success => 'You are now logged in as "' + @user.name + '"' }
        format.json { head :no_content }
      else
        session[:failedLogins] ||= 0
        session[:failedLogins] += 1
        if session[:failedLogins] >= MAX_LOGINS
          session[:blocked] = true
          redirectIfDOSingOrTooManyLogins
        else
          format.html { redirect_to :action => "login", :error => 'Given name/pattern combination not found.'}
          format.json { head :no_content }
        end
      end
    end
  end

  # GET /users/logout
  # GET /users/logout.json
  def logout
    return if redirectIfDOSingOrTooManyLogins
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
    return if redirectIfDOSingOrTooManyLogins

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
    return if redirectIfDOSingOrTooManyLogins
    return if redirectIfLoggedIn

    @user = User.new

    createNewPattern()

    generateNewPatternIfNewPage('new')

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # POST /users/create
  # POST /users/create.json
  def create
    return if redirectIfDOSingOrTooManyLogins
    return if redirectIfLoggedIn

    encrypt = PolygonAuth::PolygonEncrypt.new

    patternValidation, logicalPattern = convertPatternToLogicalForm()

    respond_to do |format|
      if !patternValidation.empty?
        format.html { redirect_to :action => "new", error: validation }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      else
        @user.password = encrypt.encryptPattern(logicalPattern)
        if @user.save
          storeVerticesInSession(true) # force
          format.html { redirect_to :action => "index", success: 'User ' + @user[:name] + ' was successfully created.' }
          format.json { render json: @user, status: :created, location: @user }
        else
          createNewPattern()
          format.html { render action: "new" }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # NOTE: Not actually available.
  # GET /users/blocked
  # GET /users/blocked.json
  def blocked
    @blocked = session[:blocked]

    respond_to do |format|
      format.html # blocked.html.erb
      format.json { head :no_content }
    end
  end

  # NOTE: Not actually available.
  # GET /users/dos
  # GET /users/dos.json
  def dos
    @dos = session[:dos]

    respond_to do |format|
      format.html # dos.html.erb
      format.json { head :no_content }
    end
  end
end
