%w{sinatra data_mapper shotgun haml dm-migrations dm-validations dm-timestamps dm-sqlite-adapter dm-postgres-adapter}.each { |lib| require lib}
DataMapper.setup(:default, ENV["DATABASE_URL"] || "sqlite3://#{Dir.pwd}/slis.db")
use Rack::MethodOverride

	
class Project
	include DataMapper::Resource
	property :id, Serial
	property :name, Text 
	property :description, Text
	property :positions, Integer 
	property :created_at, DateTime
	has n, :requests
	belongs_to :organization, :required => false
end	

class Organization 
	include DataMapper::Resource 
	property :id, Serial
	property :name, Text
	property :created_at, DateTime
	has n, :projects	
end 

class Request
	include DataMapper::Resource
	property :id, Serial
	property :name, Text 
	property :email_address, Text  
	property :accepted, Boolean, :default => false
	property :created_at, DateTime
	belongs_to :project, :required => false
end

DataMapper.auto_upgrade!

helpers do

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['username', 'password']
  end
end

get '/' do
  @random_projects = Project.all :order => :id.desc
	@recent_projects = Project.all :order => :id.desc
	@recent_projects = @recent_projects.first(10)
	haml :index
end 
 
get '/projects' do 
	@projects = Project.all :order => :id.desc
	@recent_projects = Project.all :order => :id.desc 
	@recent_projects = @recent_projects.first(10)
	haml :projects
end

get '/project/:id' do 
	@project = Project.get(params[:id])
	@accepted_count = @project.requests.all(:accepted => true).count
	@accepted_count = @project.positions - @accepted_count
	@recent_projects = Project.all :order => :id.desc
	@recent_projects = @recent_projects.first(10)
	haml :project	
end

get '/dash' do 
	protected!
	@requests = Request.all(:accepted => false)
	@recent_projects = Project.all :order => :id.desc 
	@recent_projects = @recent_projects.first(10)
	haml :dashboard
end

get '/report' do 
	@organizations = Organization.all :order => :id.desc
	@recent_projects = Project.all :order => :id.desc
	@recent_projects = @recent_projects.first(10)
	haml :report
end

get '/request_edit/:id' do 
	protected!
	@recent_projects = Project.all :order => :id.desc
	@recent_projects = @recent_projects.first(10)
	@request = Request.get(params[:id])
	haml :request_edit
end

post '/request_update/:id' do 
	protected!
	request = Request.get(params[:id])
	request.project_id = params[:project_id]
	request.save
	redirect "/report"
end

get '/organizations' do 
	@organizations = Organization.all :order => :id.desc
	@recent_projects = Project.all :order => :id.desc
	@recent_projects = @recent_projects.first(10)
	haml :organizations
end

get '/organization/:id' do 
	@organization = Organization.get(params[:id])
	@recent_projects = Project.all :order => :id.desc
	@recent_projects = @recent_projects.first(10)
	@org_projects = Organization.get(params[:id]).projects
	@projects_count = @org_projects.count
	haml :organization
end

get '/organization_new' do 
	protected!
	@recent_projects = Project.all :order => :id.desc
	@recent_projects = @recent_projects.first(10)
	haml :new_organization
end

get '/organization_edit/:id' do 
	protected!
	@recent_projects = Project.all :order => :id.desc
	@recent_projects = @recent_projects.first(10)
	@org = Organization.get(params[:id])
	haml :organization_edit
end

post '/organization_update/:id' do 
	protected!
	org = Organization.get(params[:id])
	org.name = params[:name]
	org.save
	redirect "/organization/#{org.id}"
end


post '/organization' do 
	protected!
	o = Organization.new 
	o.name = params[:name]
	o.created_at = Time.now
	o.save!
	redirect '/organizations'
end

delete '/organization_delete/:id' do
	protected!
	Organization.get(params[:id]).destroy
	redirect '/organizations'
end

get '/project_new/:id' do
	protected!
	@recent_projects = Project.all :order => :id.desc
	@recent_projects = @recent_projects.first(10)
	@org_id = params[:id]
	haml :new_project
end

get '/project_edit/:id' do 
	protected!
	@recent_projects = Project.all :order => :id.desc
	@recent_projects = @recent_projects.first(10)
	@project = Project.get(params[:id])
	haml :project_edit
end

post '/project_update/:id' do 
	protected!
	project = Project.get(params[:id])
	project.name = params[:name]
	project.description = params[:description]
	project.positions = params[:positions]
	project.save
	redirect "/project/#{project.id}"
end

post '/project/:id' do 
	protected!
	p = Project.new 
	p.name = params[:name]
	p.description = params[:description]
	p.positions = params[:positions].to_i 
	p.organization_id = params[:id]
	p.save
	redirect '/projects'
end

delete '/project_delete/:id' do
	protected!
	Project.get(params[:id]).destroy
	redirect '/projects'
end

post '/request/:id' do 
	s = Request.new 
	s.project_id = params[:id]
	s.name = params[:name]
	s.email_address = params[:email]
	s.created_at = Time.now
	s.save
	redirect "/project/#{s.project_id}"
end

post '/accept_request/:id' do 
	protected!
	request = Request.get(params[:id])
	request.accepted = true
	request.save 
	redirect '/dashboard'
end

delete '/deny_request/:id' do 
	protected!
	Request.get(params[:id]).destroy
	redirect '/dashboard'
end 

put '/accept_request/:id' do 
	protected!
	s = Student_Request.get(params[:id])
	s.accepted = true 
	s.save
end 
