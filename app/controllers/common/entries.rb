module Common
  module Entries
    def self.included(base)
      base.class_eval do
        include Common::Entries::InstanceMethods
      end
    end

    module InstanceMethods
      def index
        @tag = params[:tag]
        @mark = params[:mark]
        @keyword = params[:keyword]

        case
        when params[:remaining]
          _index_for_remaining(displaying_month, @tag, @mark, @keyword)
        when !params[:filter_account_id].nil?
          _index_with_filter_account_id
        when @tag.present?
          _index_with_tag(@tag)
        when @mark.present?
          _index_with_mark(@mark)
        when @keyword.present?
          _index_with_keyword(@keyword)
        else
          _index_plain(displaying_month)
        end
      end

      def create
        _create_entry
      end

      def update
        id = params[:id].to_i
        @item, @updated_item_ids, @deleted_item_ids = Teller.update_entry(@user, id, arguments_for_saving)
      end

      def destroy
        item = @user.items.find(params[:id])
        _destroy_item(item)
      end

      def show
        @item = @user.items.find(params[:id])
      end

      private

      def arguments_for_saving
        return {} if params[:entry].nil?

        prms = {}
        params[:entry].each do |k, v|
          attr = k.to_sym
          prms[attr] = case attr
                       when :amount, :adjustment_amount
                         Item.calc_amount(v)
                       when :action_date
                         parse_str_to_date(v)
                       else
                         v
                       end
        end
        prms
      end

      def parse_str_to_date(str)
        Date.parse(str)
      rescue ArgumentError
        raise InvalidDate
      end

      def _index_with_filter_account_id
        _set_filter_account_id_to_session_from_params
        @items = get_items(month: displaying_month)
      end

      def _index_with_tag(tag)
        @items = get_items(tag: tag)
      end

      def _index_with_keyword(keyword)
        @items = get_items(keyword: keyword)
      end

      def _index_with_mark(mark)
        @items = get_items(mark: mark)
      end

      def _default_action_date(month_to_display)
        month_to_display == today.beginning_of_month ? today : month_to_display
      end

      def _set_filter_account_id_to_session_from_params
        account_id = params[:filter_account_id].to_i
        session[:filter_account_id] = account_id == 0 ? nil : account_id
      end

      def _index_plain(month_to_display)
        @items = get_items(month: month_to_display)
      end

      def _get_date_by_specific_year_and_month_or_today(year, month)
        action_date = nil
        begin
          action_date = Date.new(year.to_i, month.to_i) unless today.beginning_of_month == Date.new(year.to_i, month.to_i).beginning_of_month
        rescue ArgumentError
          action_date = today
        end
        action_date || today
      end

      def _create_entry
        Item.transaction do
          @item, affected_item_ids = Teller.create_entry(@user, arguments_for_saving)
          affected_item_ids << @item.try(:id)
          @updated_item_ids = affected_item_ids.reject(&:nil?).uniq
        end
      end

      def _destroy_item(item)
        Item.transaction do
          result_of_delete = Teller.destroy_entry(@user, item.id)
          @updated_items = result_of_delete[0].map { |id| @user.items.find_by_id(id) }.reject(&:nil?)
          @deleted_item_ids = result_of_delete[1]
          @item = item
        end
      end

      def from_accounts
        from_or_to_accounts(:from_accounts)
      end

      def to_accounts
        from_or_to_accounts(:to_accounts)
      end

      def from_or_to_accounts(from_or_to = :from_accounts)
        # FIXME
        # html escape should be done in Views.
        @user.send(from_or_to).map { |a| { value: a[1], text: ERB::Util.html_escape(a[0]) } }
      end

      def _index_for_remaining(month, tag = nil, mark = nil, keyword = nil)
        month_to_display = if tag.present? || mark.present? || keyword.present?
                             nil
                           else
                             month.beginning_of_month
                           end

        @items = get_items(month: month_to_display, remain: true, tag: tag, mark: mark, keyword: keyword)
      end

      # options variation
      #   remain: true: get remaining items which are not shown at first.
      #   tag: String
      #   mark: String
      def get_items(options = {})
        if options[:month].present?
          from_date = options[:month].beginning_of_month
          to_date = options[:month].end_of_month
        end
        @user.items.partials(from_date, to_date,
                             filter_account_id: session[:filter_account_id],
                             remain: options[:remain], tag: options[:tag], mark: options[:mark], keyword: options[:keyword])
      end
    end
  end
end
