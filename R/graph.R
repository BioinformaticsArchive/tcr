######### REPERTOIRE GRAPH MANAGING ##########


#' Make repertoire graph for the given repertoire.
#' 
#' @description
#' Repertoire graph is a graph with vertices representing nucleotide or in-frame amino acid sequences (out-of-frame amino acid sequences
#' will automatically filtered out) and edges are connecting pairs of sequences with hamming distance or edit distance between them
#' no more than specified in the \code{.max.errors} function parameter.
#' 
#' @param .data Either character vector of sequences, data frame with \code{.label.col}
#' or shared repertoire (result from the \code{shared.repertoire} function) constructed based on \code{.label.col}.
#' @param .method Either "hamm" (for hamming distance) or "lev" (for edit distance). Passed to the \code{find.similar.sequences} function.
#' @param .max.errors Passed to the \code{find.similar.sequences} function.
#' @param .label.col 
#' @param .seg.col
#' @param .prob.col
#' 
#' @return Repertoire graph, i.e. igraph object with input sequences as vertices labels, ???
#' 
#' @seealso \link{shared.repertoire}, \link{find.similar.sequences}, \link{set.people.vector}, \link{get.people.names}
#' 
#' @examples
#' \dontrun{
#' data(twb)
#' twb.shared <- shared.repertoire(twb)
#' G <- make.repertoire.graph(twb.shared)
#' get.people.names(G, 300, T)  # "Subj.A|Subj.B"
#' get.people.names(G, 300, F)  # list(c("Subj.A", "Subj.B"))
#' }
make.repertoire.graph <- function (.data, .method = c('hamm', 'lev'), .max.errors = 1,
                                   .label.col = 'CDR3.amino.acid.sequence', .seg.col = 'V.segments', .prob.col = 'Probability') {
  # Make vertices and edges.
  if (has.class(.data, 'character')) {
    .data <- data.frame(A = .data, stringsAsFactors = F)
    colnames(.data) <- .label.col
  }
  G <- graph.empty(n = nrow(.data), directed=F)
  G <- add.edges(G, t(find.similar.sequences(.data[[.label.col]], .method = .method[1], .max.errors = .max.errors)))
  G <- simplify(G)
  
  # Every label is a sequence.
  G <- set.vertex.attribute(G, 'label', V(G), .data[[.label.col]])
  
  # Add V-segments to vertices.
  if (.seg.col %in% colnames(.data)) {
    G <- set.vertex.attribute(G, 'vseg', V(G), .data[[.seg.col]])
  } else {
    G <- set.vertex.attribute(G, 'vseg', V(G), 'nosegment')
  }
  
  # Set sequences' indices as in the given shared repertoire.
  G <- set.vertex.attribute(G, 'repind', V(G), 1:vcount(G))
  
  # Set probabilities for sequences.
  if (.prob.col %in% colnames(.data)) {
    G <- set.vertex.attribute(G, 'prob', V(G), .data[[.prob.col]])
  } else {
    G <- set.vertex.attribute(G, 'prob', V(G), rep.int(-1, vcount(G)))
  }
  
  # Add people to vertices.
  if ('People' %in% colnames(.data)) {
    attr(G, 'people') <- colnames(shared.matrix(.data))
    G <- set.people.vector(G, .data)
  } else {
    attr(G, 'people') <- "Individual"
    G <- set.vertex.attribute(G, 'people', V(G), 1)
    G <- set.vertex.attribute(G, 'npeople', V(G), 1)
  }
  
  G
}


#' Set and get attributes of a repertoire graph related to source people.
#' 
#' @aliases set.people.vector get.people.names
#' 
#' @description
#' Set vertice attributes 'people' and 'npeople' for every vertex in the given graph.
#' Attribute 'people' is a binary string indicating in which repertoire sequence are
#' found. Attribute 'npeople' is a integer indicating number of repertoires, in which
#' this sequence has been found.
#' 
#' @param .G Repertoire graph.
#' @param .shared.rep Shared repertoire.
#' @param .paste If TRUE than concatenate people names to one string, else get a character vector of names.
#' 
#' @return New graph with 'people' and 'npeople' vertex attributes or character vector of length .V or list of length .V.
#' 
#' @examples
#' \dontrun{
#' data(twb)
#' twb.shared <- shared.repertoire(twb)
#' G <- make.repertoire.graph(twb.shared)
#' get.people.names(G, 300, T)  # "Subj.A|Subj.B"
#' get.people.names(G, 300, F)  # list(c("Subj.A", "Subj.B"))
#' }
set.people.vector <- function (.G, .shared.rep) {
  .shared.rep[is.na(.shared.rep)] <- 0
  .G <- set.vertex.attribute(.G, 'people', V(.G),
                             apply(as.matrix(.shared.rep[, -(1:(match('People', colnames(.shared.rep))))]),
                                   1,
                                   function (row) { paste0(as.integer(row > 0), collapse='') }))
  set.vertex.attribute(.G, 'npeople', V(.G), .shared.rep[['People']])
}

get.people.names <- function (.G, .V = V(.G), .paste = T) {
  ppl <- attr(.G, 'people')
  if (!.paste) {
    lapply(strsplit(get.vertex.attribute(.G, 'people', .V), '', fixed=T, useBytes=T), function (l) {
      ppl[l == '1']
    })
  } else {
    sapply(strsplit(get.vertex.attribute(.G, 'people', .V), '', fixed=T, useBytes=T), function (l) {
      paste0(ppl[l == '1'], collapse='|')
    }, USE.NAMES = F)
  }
} 


#' Set group attribute for vertices of a repertoire graph
#' 
#' @aliases set.group.vector get.group.names
#' 
#' @description
#' asdasd
#' 
#' @param .shared.rep Shared repertiore of sequences.
#' @param .G Graph that was created based on \code{.shared.rep}.
#' @param .attr.name Name of the new vertex attribute.
#' @param .groups List with integer vector with indices of subjects for each group.
#' 
#' @return igraph object with new vertex attribute \code{.attr.name} with binary strings.
#' 
#' @examples
#' \dontrun{
#' data(twb)
#' twb.shared <- shared.repertoire(twb)
#' G <- make.repertoire.graph(twb.shared)
#' G <- set.group.vector(twb.shared, G, "twins", list(A = c(1,2), B = c(3,4)))
#' get.group.names(G, "twins", 1)  # "A|B"
#' get.group.names(G, "twins", 300)  # "A"
#' # Because we have only two groups, we can assign more readable attribute.
#' V(G)$twin.names <- get.group.names(G, "twins")
#' V(G)$twin.names[1]  # "A|B"
#' V(G)$twin.names[300]  # "A"
#' }
set.group.vector <- function (.shared.rep, .G, .attr.name, .groups) {
  attr(.G, .attr.name) <- sort(names(.groups))
  d <- shared.matrix(.shared.rep)
  
  group.vec <- rep('nogroup', times = max(unlist(.groups)))
  for (gr.i in 1:length(.groups)) {
    for (elem in .groups[[gr.i]]) {
      group.vec[elem] <- names(.groups)[gr.i]
    }
  }
  
  .G <- set.vertex.attribute(.G, .attr.name, V(.G),
                            apply(d, 1, function (row) { paste0(as.integer(attr(.G, .attr.name) %in% sort(group.vec[row > 0])), collapse='') }))
  
  .G
}

get.group.names <- function (.G, .attr.name, .V = V(.G), .paste = T) {
  grs <- attr(.G, .attr.name)
  if (!.paste) {
    lapply(strsplit(get.vertex.attribute(.G, .attr.name, .V), '', fixed=T, useBytes=T), function (l) {
      grs[l == '1']
    })
  } else {
    sapply(strsplit(get.vertex.attribute(.G, .attr.name, .V), '', fixed=T, useBytes=T), function (l) {
      paste0(grs[l == '1'], collapse='|')
    }, USE.NAMES = F)
  }
}