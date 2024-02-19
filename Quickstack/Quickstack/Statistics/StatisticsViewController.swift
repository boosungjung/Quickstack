//
//  StatisticsViewController.swift
//  Quickstack
//
//  Created by BooSung Jung on 10/5/2023.
// SwiftUICharts library used https://github.com/AppPear/ChartView

import UIKit
import SwiftUICharts
import SwiftUI

class StatisticsViewController: UIViewController {
    @IBOutlet weak var statsView: UIView!
    var timeData: [Double] = []
    var score:Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print(timeData)
        navigationItem.hidesBackButton = true
        // Create a SwiftUI view
//        let chart = BarChartView(data: ChartData(points: timeData), title: "Time taken", legend: "Score = \(score)", form: ChartForm.large)
//        showGraph(chart: chart)
//
//        let chartStyle = ChartStyle(
//            backgroundColor: Color(UIColor(named: "White") ?? .clear),
//            accentColor: Colors.OrangeStart,
//            secondGradientColor: Colors.OrangeEnd,
//            textColor: Color.white,
//            legendTextColor: Color.white,
//            dropShadowColor: Color.black
//        )
            
        // code from https://github.com/AppPear/ChartView
        let chart1 = LineView(data: timeData, title: "Time taken", legend: "Score = \(score)")
        showGraph(chart: chart1)

        
        
    }
    
    @IBAction func backToProfile(_ sender: Any) {
        if let navigationController = self.navigationController {
            let viewControllers = navigationController.viewControllers
            if viewControllers.count >= 3 {
                let destinationViewController = viewControllers[viewControllers.count - 3]
                navigationController.popToViewController(destinationViewController, animated: true)
            }
        }
    }
    func showGraph(chart: some View){
        // Create a UIHostingController to host the SwiftUI view
        let hostingController = UIHostingController(rootView: chart)
        
        // Add the hosting controller's view to the statsView
        addChild(hostingController)
        hostingController.view.frame = statsView.bounds
        statsView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
