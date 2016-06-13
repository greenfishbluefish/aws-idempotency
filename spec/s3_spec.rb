describe GhostChef::S3 do
  let(:client) { GhostChef::S3.class_variable_get('@@client') }

  describe '#bucket_exists' do
    context 'finds the bucket' do
      before { stub_calls([:head_bucket, {bucket: 'bucket'}, {}]) }
      it { expect(GhostChef::S3.bucket_exists('bucket')).to be true }
    end
    context 'finds no bucket' do
      before { stub_calls([:head_bucket, {bucket: 'bucket'}, 'NotFound']) }
      it { expect(GhostChef::S3.bucket_exists('bucket')).to be false }
    end
    context 'cannot see the bucket' do
      before { stub_calls([:head_bucket, {bucket: 'bucket'}, 'Forbidden']) }
      it { expect(GhostChef::S3.bucket_exists('bucket')).to be false }
    end
    context 'times out' do
      before { stub_calls([:head_bucket, {bucket: 'bucket'}, 'TimedOut']) }
      it {
        expect {
          GhostChef::S3.bucket_exists('bucket')
        }.to raise_error Aws::S3::Errors::TimedOut
      }
    end
  end

  describe '#ensure_bucket' do
    context 'bucket exists' do
      before { stub_calls([:head_bucket, {bucket: 'bucket'}, {}]) }
      it { expect(GhostChef::S3.ensure_bucket('bucket')).to be true }
    end
    context 'bucket does not exist' do
      before { stub_calls(
        [:head_bucket, {bucket: 'bucket'}, 'NotFound'],
        [:create_bucket, {bucket: 'bucket', acl: 'private'}, {location: 'some-place'}],
      ) }
      it { expect(GhostChef::S3.ensure_bucket('bucket')).to be true }
    end
    context 'cannot create a bucket' do
      before { stub_calls(
        [:head_bucket, {bucket: 'bucket'}, 'NotFound'],
        [:create_bucket, {bucket: 'bucket', acl: 'private'}, 'Forbidden'],
      ) }
      it { expect{GhostChef::S3.ensure_bucket('bucket')}.to raise_error Aws::S3::Errors::Forbidden}
    end
  end

  describe '#upload' do
    it 'returns true with a empty file' do
      stub_calls(
        [:put_object, {
          bucket: 'bucket',
          key: 'foo',
          body: '',
          acl: 'private',
        }, {}],
      )

      expect(
        GhostChef::S3.upload('bucket', 'foo')
      ).to be true
    end

    it 'returns true with a file that has content' do
      stub_calls(
        [:put_object, {
          bucket: 'bucket',
          key: 'foo',
          body: 'abcd',
          acl: 'private',
        }, {}],
      )

      expect(
        GhostChef::S3.upload('bucket', 'foo', contents: 'abcd')
      ).to be true
    end

    it 'returns true with a file that has content and an ACL' do
      stub_calls(
        [:put_object, {
          bucket: 'bucket',
          key: 'foo',
          body: 'abcd',
          acl: 'public-read',
        }, {}],
      )

      expect(
        GhostChef::S3.upload('bucket', 'foo', contents: 'abcd', acl: 'public-read')
      ).to be true
    end
  end

  describe '#enable_website' do
    it 'with defaults' do
      stub_calls(
        [:put_bucket_website, {
          bucket: 'bucket',
          website_configuration: {
            index_document: { suffix: 'index.html' },
          },
        }, {}],
      )
      expect(GhostChef::S3.enable_website('bucket')).to be true
    end

    it 'setting index document' do
      stub_calls(
        [:put_bucket_website, {
          bucket: 'bucket',
          website_configuration: {
            index_document: { suffix: 'index.htm' },
          },
        }, {}],
      )
      expect(GhostChef::S3.enable_website('bucket', index: 'index.htm')).to be true
    end

    it 'setting error document' do
      stub_calls(
        [:put_bucket_website, {
          bucket: 'bucket',
          website_configuration: {
            index_document: { suffix: 'index.html' },
            error_document: { key: 'error.html' },
          },
        }, {}],
      )
      expect(GhostChef::S3.enable_website('bucket', error: 'error.html')).to be true
    end
  end
end
