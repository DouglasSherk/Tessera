class UsersController < ApplicationController
  include PolygonAuth
  include ActionView::Helpers::DateHelper

  MAX_LOGINS = 3
  MAX_DOS = 10

  def redirectIfDOSingOrTooManyLogins
    if session.has_key?(:dos)
      timeSinceBlocked = Time.now - session[:dos]
      if timeSinceBlocked >= 1.minutes
        session.delete(:dos)
        session.delete(:numPolygonGenerations)
      else
        @time = distance_of_time_in_words(1.minutes, Time.now - session[:dos])
        render :dos
        return true
      end
    elsif session.has_key?(:blocked)
      timeSinceBlocked = Time.now - session[:blocked]
      if timeSinceBlocked >= 1.minutes
        session.delete(:blocked)
        session.delete(:failedLogins)
      else
        @time = distance_of_time_in_words(1.minutes, Time.now - session[:blocked])
        render :blocked
        return true
      end
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

  # Returns true if a DOS attempt has been detected.
  def storeVerticesInSession(force)
    session[:security] ||= 0
    auth = PolygonAuth::PolygonGenerator.new

    if force
      session[:vertices] = auth.generatePolygon(session[:security])
      session[:firstVertex] = auth.generateFirstVertex(session[:vertices])

      session[:numPolygonGenerations] ||= 0
      session[:numPolygonGenerations] += 1

      if session[:numPolygonGenerations] >= MAX_DOS
        session[:dos] = Time.now
        redirect_to :action => "index"
        return true
      end
    else
      session[:vertices] ||= auth.generatePolygon
      session[:firstVertex] ||= auth.generateFirstVertex(session[:vertices])
    end

    return false
  end

  def generateNewPatternIfNewPage(page)
    if session[:lastPageWithPolygon] != page
      return if storeVerticesInSession(true)
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

    if !validation.empty? or !foundValidPattern
      session[:failedLogins] ||= 0
      session[:failedLogins] += 1

      if session[:failedLogins] >= MAX_LOGINS
        session[:blocked] = Time.now
        redirect_to :action => "index"
        return
      end
    end

    return if foundValidPattern and storeVerticesInSession(true) # force

    respond_to do |format|
      if !validation.empty?
        format.html { redirect_to :action => "login", :error => validation }
        format.json { head :no_content }
      elsif foundValidPattern
        session[:loggedin] = true
        format.html { redirect_to :action => "index", :success => 'You are now logged in as "' + @user.name + '"' }
        format.json { head :no_content }
      else
        format.html { redirect_to :action => "login", :error => 'Given name/pattern combination not found.'}
        format.json { head :no_content }
      end
    end
  end

  # GET /users/logout
  # GET /users/logout.json
  def logout
    return if redirectIfDOSingOrTooManyLogins
    return if redirectIfNotLoggedIn

    session.delete(:vertices)
    session.delete(:firstVertex)
    session.delete(:security)
    session.delete(:loggedin)
    session.delete(:lastPageWithPolygon)

    return if storeVerticesInSession(true) # force

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

    return if storeVerticesInSession(true) # force

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
        format.html { redirect_to :action => "new", error: patternValidation }
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
end
