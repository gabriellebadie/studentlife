require 'daffy'

module SL
	module WebDAV
		
		class InCopyXML
			def initialize(article)
				@article = article
			end
			def to_xml
				"<#{slug}><body>#{@article.body}</body></#{slug}></articles>"
			end
			def slug
				self.workflow.to_s.scan(/\w+/).join("-")
			end
		end
		
		class ArticleXML
			def initialize(context)
				@article = context.article
			end

			def get; InCopyXML.new(@article).to_xml; end
			def mime; "text/xml"; end
			def size; InCopyXML.new(@article).to_xml.size; end
			def mtime; @article.updated_at; end
		end
		
		root = Daffy::Root.new
		root.config do
			collection "Issue.scoped" do
				path ':issue'
				find :find
				interpolate :issue => "issue.davslug"

				collection "Section.scoped" do
					path ':section'
					find :find_by_url!
					interpolate :section => "section.url"

					collection "Article.includes(:workflow).where(:issue_id => issue.id, :section_id => section.id)" do
						path ':article' 
						find :find
						interpolate :article => "article.davslug"

						file ArticleXML do
							path ':file.indesign.xml'
							interpolate :file => "article.davslug"
						end
					end
				end
			end
		end
		
		class App < Daffy::Sinatra.new(root)
			error ActiveRecord::RecordNotFound do
				response.status = 404
			end
			set :raise_errors, false
			set :show_exceptions, false
			route 'PROPFIND', /[\/^]\./ do
				throw(:halt, [404, "Not found\n"])
			end
		end
	end
end
