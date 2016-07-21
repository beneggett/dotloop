module Dotloop
  class Loop
    attr_accessor :client
    BATCH_SIZE = 50
    MAX_LOOPS = 500

    def initialize(client:)
      @client = client
    end

    def all(options = {})
      loops = []
      options[:batch_size] = BATCH_SIZE
      (1..MAX_LOOPS).each do |i|
        options[:batch_number] = i
        current_batch = batch(options)
        loops += current_batch
        break if current_batch.size < BATCH_SIZE
      end
      loops
    end

    def batch(options = {})
      @client.get("/profile/#{profile_id(options)}/loop", query_params(options)).map do |attrs|
        Dotloop::Models::Loop.new(attrs)
      end
    end

    def find(profile_id:, loop_view_id:)
      loop_data = @client.get("/profile/#{profile_id.to_i}/loop/#{loop_view_id.to_i}").first
      Dotloop::Models::Loop.new(loop_data)
    end

    def detail(profile_id:, loop_view_id:)
      loop_detail = @client.get("/profile/#{profile_id.to_i}/loop/#{loop_view_id.to_i}/detail")
      loop_detail[:sections] = fixed_sections(loop_detail[:sections])
      Dotloop::Models::LoopDetail.new(loop_detail)
    end

    private

    def fixed_sections(sections)
      sections.each_with_object({}) do |item, memo|
        memo[item[0].to_s.downcase.tr(' ', '_')] = item[1]
      end
    end

    def query_params(options)
      {
        batchNumber:         batch_number(options),
        batchSize:           batch_size(options),
        statusIds:           status_ids(options),
        complianceStatusIds: compliance_status_ids(options),
        tagIds:              tag_ids(options),
        sortBy:              options[:sort_by],
        searchQuery:         options[:search_query],
        tagNames:            options[:tag_names],
        createdByMe:         created_by_me(options)
      }.delete_if { |_, v| v.nil? }
    end

    def profile_id(options)
      raise 'profile_id is required' unless options[:profile_id]
      options[:profile_id].to_i
    end

    def batch_number(options)
      zero_to_nil(options[:batch_number])
    end

    def batch_size(options)
      size = options[:batch_size].to_i
      size.between?(1, BATCH_SIZE) ? size : BATCH_SIZE
    end

    def status_ids(options)
      empty_to_nil([options[:status_ids]].flatten.map { |value| zero_to_nil(value) }.compact)
    end

    def compliance_status_ids(options)
      empty_to_nil([options[:compliance_status_ids]].flatten.map { |value| zero_to_nil(value) }.compact)
    end

    def tag_ids(options)
      empty_to_nil([options[:tag_ids]].flatten.map { |value| zero_to_nil(value) }.compact)
    end

    def created_by_me(options)
      zero_to_nil(options[:created_by_me])
    end

    def zero_to_nil(value)
      return if value.to_i < 1
      value.to_i
    end

    def empty_to_nil(value)
      return if value.empty?
      value
    end
  end
end
