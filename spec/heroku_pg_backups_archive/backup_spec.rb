describe HerokuPgBackupsArchive::Backup do
  describe ".create" do
    let(:backup_output) { double(:backup_output) }
    let(:backup_object) { double(:backup_object) }

    before do
      allow(HerokuPgBackupsArchive::ToolbeltHelper).to receive(:capture_backup).and_return(backup_output)
      allow(HerokuPgBackupsArchive::Backup).to receive(:new).with(backup_output).and_return(backup_object)
    end

    it "creates a new backup and returns a `Backup` object" do
      expect(HerokuPgBackupsArchive::Backup.create).to eq backup_object
    end
  end

  describe "#id" do
    context "when the backup succeeds" do
      let(:backup_output) do
        <<-SQL
Use Ctrl-C at any time to stop monitoring progress; the backup
will continue running. Use heroku pg:backups info to check progress.
Stop a running backup with heroku pg:backups cancel.

HEROKU_POSTGRESQL_COLOR ---backup---> b022
        SQL
      end

      it "extracts the ID from output" do
        expect(HerokuPgBackupsArchive::Backup.new(backup_output).id).to eq "b022"
      end
    end

    context "when the backup succeeds" do
      let(:backup_output) { "Something something failure" }

      it "raises an exception" do
        expect { HerokuPgBackupsArchive::Backup.new(backup_output) }.to raise_error(HerokuPgBackupsArchive::BackupFailedError)
      end
    end
  end

  describe "#url" do
    let(:backup_object) { HerokuPgBackupsArchive::Backup.new(backup_output) }
    let(:backup_output) do
      <<-SQL
use ctrl-c at any time to stop monitoring progress; the backup
will continue running. use heroku pg:backups info to check progress.
stop a running backup with heroku pg:backups cancel.

heroku_postgresql_color ---backup---> b022
      SQL
    end
    let(:public_url) { "http://example.com/foo3432423\n" }

    before do
      allow(HerokuPgBackupsArchive::ToolbeltHelper).to receive(:fetch_backup_public_url).with("b022").and_return(public_url)
    end

    it "returns the chomped URL returned by heroku" do
      expect(backup_object.url).to eq "http://example.com/foo3432423"
    end
  end

  describe "#finished_at" do
    let(:backup_object) { HerokuPgBackupsArchive::Backup.new(backup_output) }
    let(:backup_output) do
      <<-SQL
use ctrl-c at any time to stop monitoring progress; the backup
will continue running. use heroku pg:backups info to check progress.
stop a running backup with heroku pg:backups cancel.

heroku_postgresql_color ---backup---> b022
      SQL
    end
    let(:backup_info) do
      <<-SQL
=== Backup info: b022
Database:    COLOR
Started:     2015-05-05 19:11:04 +0000
Finished:    2015-05-05 19:11:05 +0000
Status:      Completed Successfully
Type:        Manual
Original DB Size: 1024.0MB
Backup Size:      1024.0MB (0% compression)
=== Backup Logs
2015-05-05 19:11:04 +0000: waiting for pg_dump to complete
2015-05-05 19:11:05 +0000: pg_dump done
2015-05-05 19:11:05 +0000: waiting for upload to complete
2015-05-05 19:11:05 +0000: upload done
      SQL
    end

    before do
      allow(HerokuPgBackupsArchive::ToolbeltHelper).to receive(:fetch_backup_info).with("b022").and_return(backup_info)
    end

    it "returns the time that the backup finished" do
      expect(backup_object.finished_at).to eq Time.parse("2015-05-05 19:11:05 +0000")
    end
  end
end