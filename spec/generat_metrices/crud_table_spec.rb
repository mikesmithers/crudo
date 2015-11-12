describe 'generate metrics for a table' do

  def get_results(table_name, table_owner)
    plsql.select <<-SQL, table_name, table_owner
      select object_owner, object_name, object_type,
          create_flag, read_flag, update_flag, delete_flag
      from crudo.crud_matrices
      where table_owner = :table_owner
      and table_name = :table_name
    SQL
  end

  before(:all) do
    plsql.execute 'CREATE TABLE tst_table(aa INTEGER)'
  end

  describe 'view references' do
    before(:all) do
      plsql.execute <<-SQL
        CREATE VIEW tst_view AS SELECT * FROM tst_table
      SQL

      @expected = [
        { object_owner: 'HR',
          object_name: 'TST_VIEW',
          object_type: 'VIEW',
          create_flag: 'N',
          read_flag: 'Y',
          update_flag: 'N',
          delete_flag: 'N'
        }
      ]
    end

    it 'generates metrics for views referencing a table' do
      plsql.crudo.generate_matrices.crud_table('HR', 'TST_TABLE');

      expect( get_results('HR','TST_TABLE') ).to eq @expected
    end

    it 'accepts case-insensitive parameters' do
      plsql.crudo.generate_matrices.crud_table('HR', 'TST_TABLE');

      expect( get_results('hR','Tst_tAblE') ).to eq @expected
    end

    after(:all) do
      plsql.execute 'DROP VIEW tst_view'
    end
  end

  after(:all) do
    plsql.execute 'DROP TABLE tst_table'
  end

end
