# frozen_string_literal: true

RSpec.describe Omniauth::Cul::PermissionFileValidator do
  let(:permission_file_content) do
    {
      'development' => {
        'allowed_user_ids' => %w[abc123 def123 ghi123],
        'allowed_user_affils' => ['CUL_dpts-ldpd']
      },
      'test' => {
        'allowed_user_ids' => %w[abc123 def123 ghi123],
        'allowed_user_affils' => ['CUL_dpts-ldpd']
      }
    }
  end

  let(:config_file_path) { '/path/to/config/permissions.yml' }

  let(:rails_mock) do
    rails = instance_double('Rails')
    root_mock = instance_double('path')
    allow(root_mock).to receive(:join).and_return(config_file_path)
    allow(rails).to receive(:root).and_return(root_mock)
    allow(rails).to receive(:env).and_return('test')
    rails
  end

  describe '.permission_file_data' do
    before do
      stub_const('Rails', rails_mock)
      allow(YAML).to receive(:unsafe_load_file).with(config_file_path).and_return(permission_file_content)
    end

    it 'returns the expected value' do
      expect(described_class.permission_file_data).to eq(permission_file_content['test'])
    end
  end

  describe '.allowed_user_ids' do
    before do
      allow(described_class).to receive(:permission_file_data).and_return(permission_file_content['test'])
    end

    it 'returns the expected values' do
      expect(described_class.allowed_user_ids).to eq(permission_file_content['test']['allowed_user_ids'])
    end
  end

  describe '.allowed_user_affils' do
    before do
      allow(described_class).to receive(:permission_file_data).and_return(permission_file_content['test'])
    end

    it 'returns the expected values' do
      expect(described_class.allowed_user_affils).to eq(permission_file_content['test']['allowed_user_affils'])
    end
  end

  describe '.permitted?' do
    let(:permitted_user_id) { 'abc123' }
    let(:other_user_id) { 'zzz999' }
    let(:empty_affils) { [] }
    let(:array_containing_permitted_affil) do
      [
        'other_affil_1',
        permission_file_content['test']['allowed_user_affils'].first,
        'other_affil_2'
      ]
    end

    before do
      allow(described_class).to receive(:permission_file_data).and_return(permission_file_content['test'])
    end

    it 'returns true for a permitted user' do
      expect(described_class.permitted?(permitted_user_id, empty_affils)).to eq(true)
    end

    it 'returns false for a user who has not been explicitly permitted and has no explicitly permitted affiliations' do
      expect(described_class.permitted?(other_user_id, empty_affils)).to eq(false)
    end

    it 'returns true for a user who has not been explicitly permitted but has an explicitly permitted affiliation' do
      expect(described_class.permitted?(other_user_id, array_containing_permitted_affil)).to eq(true)
    end
  end
end
