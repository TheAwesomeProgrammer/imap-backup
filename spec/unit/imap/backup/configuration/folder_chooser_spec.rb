describe Imap::Backup::Configuration::FolderChooser do
  include HighLineTestHelpers

  describe "#run" do
    subject { described_class.new(account) }

    let(:connection) do
      instance_double(
        Imap::Backup::Account::Connection, folders: connection_folders
      )
    end
    let(:account) { {folders: []} }
    let(:connection_folders) { [] }
    let!(:highline_streams) { prepare_highline }
    let(:input) { highline_streams[0] }
    let(:output) { highline_streams[1] }

    before do
      allow(Imap::Backup::Account::Connection).to receive(:new) { connection }
      allow(Kernel).to receive(:system)
      allow(Imap::Backup.logger).to receive(:warn)
    end

    describe "display" do
      it "clears the screen" do
        expect(Kernel).to receive(:system).with("clear")

        subject.run
      end

      it "shows the menu" do
        subject.run

        expect(output.string).to match %r{Add/remove folders}
      end
    end

    describe "folder listing" do
      let(:account) { {folders: [{name: "my_folder"}]} }
      let(:connection_folders) do
        # N.B. my_folder is already backed up
        %w(my_folder another_folder)
      end

      describe "display" do
        before { subject.run }

        it "shows folders which are being backed up" do
          expect(output.string).to include("+ my_folder")
        end

        it "shows folders which are not being backed up" do
          expect(output.string).to include("- another_folder")
        end
      end

      context "when adding folders" do
        before do
          allow(input).to receive(:gets).and_return("2\n", "q\n")

          subject.run
        end

        specify "are added to the account" do
          expect(account[:folders]).to include(name: "another_folder")
        end
      end

      context "when removing folders" do
        before do
          allow(input).to receive(:gets).and_return("1\n", "q\n")

          subject.run
        end

        specify "are removed from the account" do
          expect(account[:folders]).to_not include(name: "my_folder")
        end
      end
    end

    context "with missing remote folders" do
      let(:account) do
        {folders: [{name: "on_server"}, {name: "not_on_server"}]}
      end
      let(:connection_folders) do
        [
          instance_double(Imap::Backup::Account::Folder, name: "on_server")
        ]
      end

      before do
        allow(Kernel).to receive(:puts)
        subject.run
      end

      specify "are removed from the account" do
        expect(account[:folders]).to_not include(name: "not_on_server")
      end
    end

    context "when folders are not available" do
      let(:connection_folders) { nil }

      before do
        allow(Imap::Backup::Configuration::Setup.highline).
          to receive(:ask) { "q" }
      end

      it "asks to press a key" do
        expect(Imap::Backup::Configuration::Setup.highline).
          to receive(:ask).with("Press a key ")

        subject.run
      end
    end

    context "with connection errors" do
      before do
        allow(Imap::Backup::Account::Connection).
          to receive(:new).with(account).and_raise("error")
        allow(Imap::Backup::Configuration::Setup.highline).
          to receive(:ask) { "q" }
      end

      it "prints an error message" do
        expect(Imap::Backup.logger).
          to receive(:warn).with("Connection failed")

        subject.run
      end

      it "asks to continue" do
        expect(Imap::Backup::Configuration::Setup.highline).
          to receive(:ask).with("Press a key ")

        subject.run
      end
    end
  end
end
