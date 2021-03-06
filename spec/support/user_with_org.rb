require "support/shared_space"
require "timeout"

module UserWithOrgHelpers
  def with_user_with_org
    let(:admin_user) { AdminUser.from_env }
    let(:regular_user) { RegularUser.from_env }

    if org_name = ENV["NYET_ORGANIZATION_NAME"]
      before { @org = regular_user.find_organization_by_name(org_name) }
    else
      before { @org = admin_user.create_org(regular_user.user) }
      after { admin_user.delete_org }
    end
    let(:org) { @org }
  end

  def with_new_space
    # - `after`s are done in reverse order!
    # - failing in one after does not prevent execution of subsequent afters
    before { @space = regular_user.create_space(org) }
    after { @space.delete!(:recursive => true) if @space }
    let(:space) { @space }
  end

  def with_shared_space
    let!(:space) {
      SharedSpace.instance {
        if space_name = ENV["NYET_SPACE_NAME"]
          org.space_by_name(space_name) or raise "No such space"
        else
          regular_user.create_space(org)
        end
      }.tap do |space|
        puts "--- find: #{space.inspect} (org: #{org})"
      end
    }
  end

  def with_time_limit(limit=600)
    around do |example|
      Timeout.timeout(limit) do
        example.run
      end
    end
  end
end

RSpec.configure do |config|
  config.extend(UserWithOrgHelpers)
end
