******************************************
Diffusion Methods Package V1.1
Michael Donoser
michael.donoser@tugraz.at
Institute for Computer Graphics and Vision
Graz University of Technology
http://icg.tugraz.at/members/donoser
Virtual Habitat Group
http://vh.icg.tugraz.at
******************************************


DESCRIPTION
  This is a Matlab implementation of several diffusion variants 
  for improving pairwise similarity measures provided in terms of an  
  affinity matrix, by re-evaluating the affinities in context of 
  all database elements (considering the underlying manifold). 
  Thus, in general an affinity matrix is the input and a diffused 
  affinity matrix is the output. Although being a generic concept,
  in this package diffusion is evaluated in the scope of retrieval.
  
PUBLICATION 
  When using this software, please acknowledge the effort that 
  went into development by referencing the paper:
  *********************************************
  "Diffusion Processes for Retrieval Revisited"
  Michael Donoser and Horst Bischof
  Proceedings of Conference on Computer Vision 
  and Pattern Recognition (CVPR), 2013
  *********************************************
  

CONTENT
  The package contains three main parts
  
  1) Scripts for directly reproducing results and figures of the main paper
     --- ICG_ExperimentCVPR2013_Section_4_1 ... Reproduce results of Section 4.1
     --- ICG_ExperimentCVPR2013_Section_4_2 ... Reproduce results of Section 4.2  
     	 
  2) An efficient implementation of the most promising diffusion variant
     --- ICG_ApplyDiffusionProcess ... Implementation
     --- ICG_ExampleDiffusionProcess ... Example of how to use the method

  3) A large-scale variant for handling really large affinity matrices
     --- ICG_ApplyDiffusionProcessOnHugeMatrices ... Implementation
     --- ICG_ExampleLargeScaleDiffusionProcess .. Example of how to use

HOW TO START

  Probably the best starting point is to start the DEMO script. This script
  calls ICG_ExampleDiffusionProcess and ICG_ExampleLargeScaleDiffusionProcess,
  which demonstrate how to apply the diffusion method on two
  different datasets.

DEPENDENCIES

  The methods for reproducing results of the CVPR 2013 paper do not have any
  dependencies and should work in all Matlab versions on all platforms

  The efficient implementation ICG_ApplyDiffusionProcess requires the 
  Min/Max selection tool by Bruno Luong available at the Matlab Central
  'http://www.mathworks.com/matlabcentral/fileexchange/23576-minmax-selection?download=true' 
  Nevertheless, it should be automatically installed if not available.

  The large scale implementation requires a nearest neighbor algorithm. In 
  this package we use the algorithm provided in the VL-Feat Toolbox 
  Download at http://www.vlfeat.org/

CONTACT
  If you find any errors or have comments please contact
  michael.donoser@tugraz.at

LICENSE
  This code is licensed under the Lesser GPL (see  
  http://www.gnu.org/copyleft/lesser.html and License/lgpl.txt)

ACKNOWLEDGEMENTS
  We gratefully acknowledge contributions concenring package improvements 
  of David Ferstl (http://rvlab.icg.tugraz.at/personal_page/personal_page_ferstl.htm)

CHANGES
  beta-1     Initial public release (14.4.2013)
  beta-1.1   Added visualization possibilities
  