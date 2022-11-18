# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class TemplateRenderContextInputType < Gql::Types::BaseInputObject
    description 'Context data for template rendering, e.g. customer data.'

    argument :customer_id, GraphQL::Types::ID, loads: Gql::Types::UserType, required: false, description: 'Ticket customer (if no ticket exists yet)'
    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, required: false, description: 'Ticket'

    # Prepare a hash suitable for usage in NotificationFactory.
    def to_context_hash
      to_h.tap do |result|
        # Inject current user as `user`.
        result[:user] = context.current_user
        # If ticket does not exist yet, fake it with a customer if present.
        if !ticket && customer
          result[:ticket] = ::Ticket.new(customer: customer)
        end
      end
    end
  end
end
