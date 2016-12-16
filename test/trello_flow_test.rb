require "test_helper"

module TrelloFlow
  class TrelloFlowTest < Minitest::Test
    def setup
      Cli.client = cli
      stub_trello(:get, "/tokens/MEMBER_TOKEN/member").to_return_json(member)
    end

    def dont_test_git_start
      card_endpoint = stub_trello(:get, "/cards/CARD_ID").to_return_json(card)
      board_endpoint = stub_trello(:get, "/boards/BOARD_ID").to_return_json(board)
      lists_endpoint = stub_trello(:get, "/boards/BOARD_ID/lists").to_return_json([backlog, started, finished])
      move_to_list_endpoint = stub_trello(:put, "/cards/CARD_ID/idList").with(body: { value: "STARTED_LIST_ID" })
      add_member_endpoint = stub_trello(:post, "/cards/CARD_ID/members").with(body: { value: "MEMBER_ID" })

      cli.expect :read, "master", ["git rev-parse --abbrev-ref HEAD"]
      cli.expect :run, nil, ["git checkout master.card-name.CARD_ID || git checkout -b master.card-name.CARD_ID"]

      trello_flow.start(card_url)

      cli.verify
      assert_requested card_endpoint
      assert_requested board_endpoint
      assert_requested lists_endpoint
      assert_requested move_to_list_endpoint
      assert_requested add_member_endpoint
    end

    def test_git_start_with_name
      boards_endpoint = stub_trello(:get, "/members/MEMBER_ID/boards").with(query: { filter: "open" }).to_return_json([board])
      lists_endpoint = stub_trello(:get, "/boards/BOARD_ID/lists").to_return_json([backlog, started, finished])
      create_card_endpoint = stub_trello(:post, "/lists/BACKLOG_LIST_ID/cards").to_return_json(card)
      board_endpoint = stub_trello(:get, "/boards/BOARD_ID").to_return_json(board)
      move_to_list_endpoint = stub_trello(:put, "/cards/CARD_ID/idList").with(body: { value: "STARTED_LIST_ID" })
      add_member_endpoint = stub_trello(:post, "/cards/CARD_ID/members").with(body: { value: "MEMBER_ID" })

      cli.expect :table, nil, [Array]
      cli.expect :ask, 1, ["Pick one:", Integer]
      cli.expect :read, "master", ["git rev-parse --abbrev-ref HEAD"]
      cli.expect :run, nil, ["git checkout master.card-name.CARD_ID || git checkout -b master.card-name.CARD_ID"]

      trello_flow.start("NEW CARD NAME")

      cli.verify
      assert_requested boards_endpoint
      assert_requested lists_endpoint, at_least_times: 1
      assert_requested create_card_endpoint
      assert_requested board_endpoint
      assert_requested move_to_list_endpoint
      assert_requested add_member_endpoint
    end

    def dont_test_git_start_with_blank_name
      boards_endpoint = stub_trello(:get, "/members/MEMBER_ID/boards").with(query: { filter: "open" }).to_return_json([board])
      lists_endpoint = stub_trello(:get, "/boards/BOARD_ID/lists").to_return_json([backlog, started, finished])
      cards_endpoint = stub_trello(:get, "/lists/BACKLOG_LIST_ID/cards").to_return_json([card])
      board_endpoint = stub_trello(:get, "/boards/BOARD_ID").to_return_json(board)
      move_to_list_endpoint = stub_trello(:put, "/cards/CARD_ID/idList").with(body: { value: "STARTED_LIST_ID" })
      add_member_endpoint = stub_trello(:post, "/cards/CARD_ID/members").with(body: { value: "MEMBER_ID" })

      cli.expect :table, nil, [Array]
      cli.expect :ask, 1, ["Pick one:", Integer]
      cli.expect :table, nil, [Array]
      cli.expect :ask, 1, ["Pick one:", Integer]
      cli.expect :read, "master", ["git rev-parse --abbrev-ref HEAD"]
      cli.expect :run, nil, ["git checkout master.card-name.CARD_ID || git checkout -b master.card-name.CARD_ID"]

      trello_flow.start(nil)

      cli.verify
      assert_requested boards_endpoint
      assert_requested lists_endpoint, at_least_times: 1
      assert_requested cards_endpoint
      assert_requested board_endpoint
      assert_requested move_to_list_endpoint
      assert_requested add_member_endpoint
    end

    #def test_git_open
      #stub_trello(:get, "/checklists/CHECKLIST_ID/checkItems/ITEM_ID").to_return_json(item)
      #stub_trello(:get, "/checklists/CHECKLIST_ID").to_return_json(checklist)
      #stub_trello(:get, "/cards/CARD_ID").to_return_json(card)

      #cli.expect :read, "master.item-task.CHECKLIST_ID-ITEM_ID", ["git rev-parse --abbrev-ref HEAD"]
      #cli.expect :open_url, nil, ["https://trello.com/c/CARD_ID/2-trello-flow"]

      #trello_flow.open
      #cli.verify
    #end

    def test_git_finish
      card_endpoint = stub_trello(:get, "/cards/CARD_ID").to_return_json(card)
      lists_endpoint = stub_trello(:get, "/boards/BOARD_ID/lists").to_return_json([backlog, started, finished])
      board_endpoint = stub_trello(:get, "/boards/BOARD_ID").to_return_json(board)
      move_to_list_endpoint = stub_trello(:put, "/cards/CARD_ID/idList").with(body: { value: "FINISHED_LIST_ID" })

      cli.expect :read, "master.card-name.CARD_ID", ["git rev-parse --abbrev-ref HEAD"]
      cli.expect :run, nil, ["git push origin master.card-name.CARD_ID -u"]
      cli.expect :read, "git@github.com:balvig/trello_flow.git", ["git config --get remote.origin.url"]
      cli.expect :open_url, nil, ["https://github.com/balvig/trello_flow/compare/master...master.card-name.CARD_ID?expand=1&title=CARD%20NAME&body=Trello:%20#{card_url}"]

      trello_flow.finish

      cli.verify
      assert_requested card_endpoint
      assert_requested lists_endpoint
      assert_requested board_endpoint
      assert_requested move_to_list_endpoint
    end

    private

      def card_url
        "https://trello.com/c/CARD_ID/2-trello-flow"
      end

      def member
        { id: "MEMBER_ID", username: "balvig" }
      end

      def board
        { name: "BOARD NAME", id: "BOARD_ID" }
      end

      def backlog
        { id: "BACKLOG_LIST_ID" }
      end

      def started
        { id: "STARTED_LIST_ID" }
      end

      def finished
        { id: "FINISHED_LIST_ID" }
      end

      def card
        { id: "CARD_ID", name: "CARD NAME", idBoard: "BOARD_ID", shortUrl: card_url }
      end

      def checklist(items: [item, item])
        { id: "CHECKLIST_ID", name: "CHECKLIST NAME", checkItems: items, idCard: "CARD_ID" }
      end

      def item
        { id: "ITEM_ID", name: "ITEM TASK @owner", idChecklist: "CHECKLIST_ID", state: "incomplete" }
      end

      def cli
        @_cli ||= Minitest::Mock.new
      end

      def trello_flow
        @_trello_flow ||= Main.new Config.new(key: "PUBLIC_KEY", token: "MEMBER_TOKEN")
      end
  end
end
