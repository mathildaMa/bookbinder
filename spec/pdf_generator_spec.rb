require 'spec_helper'

describe PdfGenerator do
  let(:logger) { NilLogger.new }
  let(:target_dir) { Dir.mktmpdir }
  let(:header_file) do
    header_file = File.join(target_dir, 'pdf_header.html')
    File.open(header_file, 'w') { |f| f.write('Header!') }
    header_file
  end

  let(:source_page) do
    source_page = File.join(target_dir, 'pdf_source.html')
    File.open(source_page, 'w') { |f| f.write('Hi!') }
    source_page
  end
  let(:generated_pdf) { File.join(target_dir, 'generated.pdf')}

  it 'generates a PDF from the specified pages and header' do
    PdfGenerator.new(logger).generate [source_page], generated_pdf, header_file
    expect(File.exist? generated_pdf).to be_true
  end

  context 'when generating pages from a live web-server' do
    before do
      stub_request(:get, "http://example.com/").to_return(:status => 200, :body => `fortune`, :headers => {})
    end

    it 'generates a PDF from a live web-page and header' do
      many_pages = 110.times.map { 'http://example.com' }
      PdfGenerator.new(logger).generate many_pages, generated_pdf, header_file
      expect(File.exist? generated_pdf).to be_true
    end
  end

  it 'raises an exception if the specified source URL does not exist' do
    bad_website = 'http://website.invalid/pdf.html'
    stub_request(:get, bad_website).to_return(:status => 404)
    expect do
      PdfGenerator.new(logger).generate [bad_website], 'irrelevant.pdf', header_file
    end.to raise_error(/Could not find file #{Regexp.escape(bad_website)}/)
  end

  it 'raises an exception if the specified header file does not exist' do
    expect do
      PdfGenerator.new(logger).generate [source_page], 'irrelevant.pdf', 'not_there.html'
    end.to raise_error(/Could not find file not_there.html/)
  end

  it 'raises an exception if the tool does not produce a PDF' do
    pdf_destination = '/dev/null/doomed.pdf'

    expect do
      PdfGenerator.new(logger).generate [source_page], pdf_destination, header_file
    end.to raise_error(/'wkhtmltopdf' appears to have failed/)
  end
end