class Racer
  include ActiveModel::Model
  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs


  #MONGO_URI = ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017'
  #MONGO_DATABASE = 'coursera_racers'
  RACE_COLLECTION = 'racers'


  def initialize(params={})
    @id = params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i
  end

  def persisted?
    !@id.nil?
  end

  def created_at
    nil
  end

  def updated_at
    nil
  end

  def save
    result = self.class.collection
                 .insert_one({number: @number,
                             first_name: @first_name,
                             last_name: @last_name,
                             gender: @gender,
                             group: @group,
                             secs: @secs})
    @id = result.inserted_id.to_s
  end

  def update(params)
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i

    params.slice!(:number, :first_name, :last_name,
                  :gender, :group, :secs)
    id = BSON::ObjectId.from_string(@id)
    self.class.collection.find(:_id => id)
        .update_one(params)
  end

  def destroy
    id = BSON::ObjectId.from_string(@id)
    self.class.collection.find(_id: id)
                          .delete_one
  end

  def self.paginate(params)
    page = (params[:page] || 1).to_i
    limit = (params[:per_page]|| 30).to_i
    skip = (page-1)*limit
    racers = []
    all({},{},skip,limit).each  do |racer|
      racers << Racer.new(racer)
    end
    total = Racer.all.count
    WillPaginate::Collection.create(page, limit, total) do |pager|
     pager.replace(racers)
    end
  end

  def self.mongo_client
    #db = Mongo::Client.new MONGO_URI
    #db = db.use(MONGO_DATABASE)
    Mongoid::Clients.default
  end

  def self.collection
    return mongo_client[RACE_COLLECTION]
  end

  def self.all(prototype={}, sort={number: 1}, offset=0, limit=nil)
    results = self.collection
                  .find(prototype)
                  .sort(sort)
                  .skip(offset)
    results = results.limit(limit) unless limit.nil?
    return results
  end

  def self.find (id)
    id = BSON::ObjectId id
    doc = collection.find(:_id => id).first
    return doc.nil? ? nil : Racer.new(doc)
  end

end