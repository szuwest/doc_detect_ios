//
//  fm_ocr_scanner.hpp
//  FMHEDNet
//
//  Created by fengjian on 2018/4/11.
//  Copyright © 2018年 fengjian. All rights reserved.
//

#ifndef fm_ocr_scanner_hpp
#define fm_ocr_scanner_hpp

#include <stdio.h>
#include <array>
#include <tuple>
#include <opencv2/core/core.hpp>

std::tuple<bool, std::vector<cv::Point> > ProcessEdgeImage(cv::Mat edge_image);

#endif /* fm_ocr_scanner_hpp */
