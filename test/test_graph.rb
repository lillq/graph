require "minitest/autorun"
require "tmpdir"
require "graph"

class String
  def clean
    gsub(/\s+(\[|\])/, ' \1')
  end
end

class TestGraph < MiniTest::Unit::TestCase
  attr_accessor :graph

  def assert_attribute k, v, a
    assert_kind_of Graph::Attribute, a
    assert_equal "#{k} = #{v}", a.attr
  end

  def assert_graph graph, *lines
    lines = lines.map { |l| "    #{l};" }.join("\n")
    expected = "digraph \n  {\n#{lines}\n  }".sub(/\n\n/, "\n")
    assert_equal expected, graph.to_s.clean
  end

  def setup
    @graph = Graph.new
    @graph["a"] >> "b"
  end

  def test_boxes
    assert_graph graph, '"a" -> "b"'

    graph.boxes

    assert_graph graph, 'node [ shape = box ]', '"a" -> "b"'
  end

  def test_colorscheme
    assert_attribute "colorscheme", "blah", graph.colorscheme("blah")
  end

  def test_fillcolor
    assert_attribute "fillcolor", "blah", graph.fillcolor("blah")
  end

  def test_font
    assert_attribute "fontname", '"blah"', graph.font("blah")
  end

  def test_font_size
    # cheating... but I didn't want to write a more complex assertion
    assert_attribute "fontname", '"blah", fontsize = 12', graph.font("blah", 12)
  end

  def test_digraph
    g = digraph do
      edge "a", "b", "c"
    end

    assert_kind_of Graph, g
    assert_equal %w(a b c), g.nodes.keys.sort
  end

  def test_edge
    @graph = Graph.new

    graph.edge "a", "b", "c"

    assert_graph graph, '"a" -> "b"', '"b" -> "c"'
  end

  def test_invert
    graph["a"] >> "c"
    invert = graph.invert
    assert_equal %w(a), invert.edges["b"].keys
    assert_equal %w(a), invert.edges["c"].keys
  end

  def test_label
    graph.label "blah"

    assert_graph graph, 'label = "blah"', '"a" -> "b"'
  end

  def test_left_shift
    subgraph = Graph.new "blah"

    graph << subgraph

    assert_equal graph, subgraph.graph
    assert_includes graph.subgraphs, subgraph
  end

  def test_nodes
    assert_equal %w(a b), graph.nodes.keys.sort
  end

  def test_orient
    graph.orient "blah"

    assert_equal ["rankdir = blah"], graph.graph_attribs
  end

  def test_orient_default
    graph.orient

    assert_equal ["rankdir = TB"], graph.graph_attribs
  end

  def test_rotate
    graph.rotate "blah"

    assert_equal ["rankdir = blah"], graph.graph_attribs
  end

  def test_rotate_default
    graph.rotate

    assert_equal ["rankdir = LR"], graph.graph_attribs
  end

  def test_save
    util_save "png"
  end

  def test_save_nil
    util_save nil
  end

  def test_shape
    assert_attribute "shape", "blah", graph.shape("blah")
  end

  def test_style
    assert_attribute "style", "blah", graph.style("blah")
  end

  def test_subgraph
    n = nil
    s = graph.subgraph "blah" do
      n = 42
    end

    assert_equal graph, s.graph
    assert_equal "blah", s.name
    assert_equal 42, n
  end

  def test_to_s
    assert_graph graph, '"a" -> "b"'

    graph["a"] >> "c"

    assert_graph graph, '"a" -> "b"', '"a" -> "c"'
  end

  def test_to_s_attrib
    graph.color("blue") << graph["a"]

    assert_graph graph, '"a" [ color = blue ]', '"a" -> "b"'
  end

  def test_to_s_edge_attribs
    graph.edge_attribs << "blah" << "halb"

    assert_graph graph, 'edge [ blah, halb ]', '"a" -> "b"'
  end

  def test_to_s_empty
    assert_graph Graph.new
  end

  def test_to_s_node_attribs
    graph.node_attribs << "blah" << "halb"

    assert_graph graph, 'node [ blah, halb ]', '"a" -> "b"'
  end

  def test_to_s_subgraph
    g = Graph.new "subgraph" do
      edge "a", "c"
    end

    graph << g

g_s = "subgraph subgraph
  {
    \"a\";
    \"c\";
    \"a\" -> \"c\";
  }"

    assert_graph(graph,
                 g_s, # HACK: indentation is really messy right now
                 '"a" -> "b"')
  end

  def util_save type
    path = File.join(Dir.tmpdir, "blah.#{$$}")

    $x = nil

    def graph.system(*args)
      $x = args
    end

    graph.save(path, type)

    assert_equal graph.to_s + "\n", File.read("#{path}.dot")
    expected = ["dot -T#{type} #{path}.dot > #{path}.png"] if type
    assert_equal expected, $x
  ensure
    File.unlink path rescue nil
  end
end

class TestAttribute < MiniTest::Unit::TestCase
  attr_accessor :a

  def setup
    self.a = Graph::Attribute.new "blah"
  end

  def test_lshift
    n = Graph::Node.new nil, nil

    a << n

    assert_equal [a], n.attributes
  end

  def test_plus
    b = Graph::Attribute.new "halb"

    c = a + b

    assert_equal "blah, halb", c.attr
  end

  def test_to_s
    assert_equal "blah", a.to_s
  end
end

class TestNode < MiniTest::Unit::TestCase
  attr_accessor :n

  def setup
    self.n = Graph::Node.new :graph, "n"
  end

  def test_rshift
    graph = Graph.new
    self.n = graph.node "blah"

    n2 = n >> "halb"
    to = graph["halb"]
    e = graph.edges["blah"]["halb"]

    assert_equal n, n2
    assert_kind_of Graph::Edge, e
    assert_kind_of Graph::Node, to
    assert_equal n, e.from
    assert_equal to, e.to
  end

  def test_index
    graph = Graph.new
    self.n = graph.node "blah"

    e = n["halb"]
    to = graph["halb"]

    assert_kind_of Graph::Edge, e
    assert_kind_of Graph::Node, to
    assert_equal n, e.from
    assert_equal to, e.to
  end

  def test_label
    n.label "blah"

    assert_equal ["label = \"blah\""], n.attributes
  end

  def test_to_s
    assert_equal '"n"', n.to_s
  end

  def test_to_s_attribs
    n.attributes << "blah"

    assert_equal '"n" [ blah ]', n.to_s.clean
  end
end

class TestEdge < MiniTest::Unit::TestCase
  attr_accessor :e

  def setup
    a = Graph::Node.new :graph, "a"
    b = Graph::Node.new :graph, "b"
    self.e = Graph::Edge.new :graph, a, b
  end

  def test_label
    e.label "blah"

    assert_equal ["label = \"blah\""], e.attributes
  end

  def test_to_s
    assert_equal '"a" -> "b"', e.to_s
  end

  def test_to_s_attribs
    e.attributes << "blah"

    assert_equal '"a" -> "b" [ blah ]', e.to_s.clean
  end
end
