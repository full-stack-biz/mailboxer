class Mailboxer::BaseBuilder

  attr_reader :params

  def initialize(params)
    @params = params.with_indifferent_access
  end

  def build
    klass.new.tap do |object|
      params.keys.each do |field|
        field_value = get(field)
        next if field_value.nil?
        assign_field(object, field, field_value)
      end
    end
  end

  protected

  def assign_field(object, field, value)
    assign_method = "assign_#{field}_field"

    if respond_to?(assign_method, true)
      send(assign_method, object, value)
    else
      object.send("#{field}=", get(field)) unless get(field).nil?
    end
  end

  def get(key)
    respond_to?(key) ? send(key) : params[key]
  end

  def recipients
    Array(params[:recipients]).uniq
  end
end
