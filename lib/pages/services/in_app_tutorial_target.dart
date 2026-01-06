import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

List<TargetFocus> addAppTargets({
  required GlobalKey CreateLeadKey,
  required GlobalKey AssignedLeadsKey,
  required GlobalKey MyToDoListKey,
  required GlobalKey CampaignKey,
  required GlobalKey RewardsKey,
  required GlobalKey TrainingKey,
  required GlobalKey SearchFilterKey,
  required GlobalKey TotalSubmitedKey,
  required GlobalKey InProgressKey,
  required GlobalKey InPrincipalApprovedKey,
  required GlobalKey FinalApprovedKey,
  required GlobalKey DeclinedKey,
  required GlobalKey DisbursedKey,
}) {
  List<TargetFocus> target = [];
  target.add(
    TargetFocus(
      identify: "Create Lead",
      keyTarget: CreateLeadKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 30,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Tap here to create New Lead",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );

  target.add(
    TargetFocus(
      identify: "Assign Leads",
      keyTarget: AssignedLeadsKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 50,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(0.0),
            child: Text(
              "Tap here to view the leads assigned to you. You can track progress, update details, and manage follow-ups.",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "My To-Do-List",
      keyTarget: MyToDoListKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 40,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Stay on top of your tasks with the To-Do List! Easily track location, and manage follow-ups to stay organized and productive.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Campaign",
      keyTarget: CampaignKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 50,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Boost your outreach with Campaigns! Manage, and track campaign performance to engage leads effectively and drive better results.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Rewards",
      keyTarget: RewardsKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 55,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(0.0),
            child: Text(
              "Unlock exciting rewards! Earn points for your achievements and redeem them for exclusive benefits.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Training",
      keyTarget: TrainingKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 55,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Enhance your skills with expert training! Access valuable resources, learn new strategies, and stay ahead in your field.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Search Filter",
      keyTarget: SearchFilterKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 15,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Easily find the leads you need! Use the Lead Type filter to categorize and search for leads based on their status and priority.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Total Accepted",
      keyTarget: TotalSubmitedKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Track your progress with Total Lead Accepted! Monitor the number of leads you've added and measure your performance effectively.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "In Progress",
      keyTarget: InProgressKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Keep track of ongoing tasks! View leads that are currently in progress.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "In Principal Approved",
      keyTarget: InPrincipalApprovedKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "View Your Number Of In-Principle Approval.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Final Approved",
      keyTarget: FinalApprovedKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "View Your Number Of Approval Leads.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Declined",
      keyTarget: DeclinedKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "View Your Number Of Declined Leads.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Disbursed",
      keyTarget: DisbursedKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "View Your Number Of Disbursed Leads.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );

  return target;
}


List<TargetFocus> addAppFRTargets({
  required GlobalKey CreateLeadKey,
  required GlobalKey AssignedLeadsKey,
  required GlobalKey MyToDoListKey,
  required GlobalKey CampaignKey,
  required GlobalKey RewardsKey,
  required GlobalKey TrainingKey,
  required GlobalKey SearchFilterKey,
  required GlobalKey TotalSubmitedKey,
  required GlobalKey InProgressKey,
  required GlobalKey InPrincipalApprovedKey,
  required GlobalKey FinalApprovedKey,
  required GlobalKey DeclinedKey,
  required GlobalKey DisbursedKey,
}) {
  List<TargetFocus> target = [];
  target.add(
    TargetFocus(
      identify: "Create Lead",
      keyTarget: CreateLeadKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 45,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Tap here to create New Lead",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );

  target.add(
    TargetFocus(
      identify: "Assign Leads",
      keyTarget: AssignedLeadsKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 50,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(0.0),
            child: Text(
              "Tap here to view the leads assigned to you. You can track progress, update details, and manage follow-ups.",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "My To-Do-List",
      keyTarget: MyToDoListKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 40,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Stay on top of your tasks with the To-Do List! Easily track location, and manage follow-ups to stay organized and productive.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Campaign",
      keyTarget: CampaignKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 50,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Boost your outreach with Campaigns! Manage, and track campaign performance to engage leads effectively and drive better results.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Rewards",
      keyTarget: RewardsKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 55,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(0.0),
            child: Text(
              "Unlock exciting rewards! Earn points for your achievements and redeem them for exclusive benefits.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Training",
      keyTarget: TrainingKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 55,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Enhance your skills with expert training! Access valuable resources, learn new strategies, and stay ahead in your field.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Search Filter",
      keyTarget: SearchFilterKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 15,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Easily find the leads you need! Use the Lead Type filter to categorize and search for leads based on their status and priority.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Total Accepted",
      keyTarget: TotalSubmitedKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Track your progress with Total Lead Accepted! Monitor the number of leads you've added and measure your performance effectively.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "In Progress",
      keyTarget: InProgressKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Keep track of ongoing tasks! View leads that are currently in progress.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "In Principal Approved",
      keyTarget: InPrincipalApprovedKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "View Your Number Of In-Principle Approval.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Final Approved",
      keyTarget: FinalApprovedKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "View Your Number Of Approval Leads.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Declined",
      keyTarget: DeclinedKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "View Your Number Of Declined Leads.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Disbursed",
      keyTarget: DisbursedKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 15,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "View Your Number Of Disbursed Leads.",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );

  return target;
}

List<TargetFocus> appTargetFsaLeadDashboard({
  required GlobalKey CreateLeadIconKey,
  required GlobalKey EditLeadIconKey,
  required GlobalKey DisplayLeadKey,
  required GlobalKey LeadDescriptionKey,
  required GlobalKey LeadFilterKey,
}) {
  List<TargetFocus> target = [];
  target.add(
    TargetFocus(
      identify: "Create Lead",
      keyTarget: CreateLeadIconKey,
      shape: ShapeLightFocus.Circle,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 10,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Tap here to Open Lead Form",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Edit Lead",
      keyTarget: EditLeadIconKey,
      shape: ShapeLightFocus.Circle,
      alignSkip: Alignment.topRight,
      radius: 5,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Tap here to Edit a Created Lead",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Created Leads",
      keyTarget: DisplayLeadKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 5,
      paddingFocus: 10,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "List Of Leads Created",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Lead Type",
      keyTarget: LeadDescriptionKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 5,
      paddingFocus: 10,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Type Of Lead Customer/Comapny",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Filter Leads",
      keyTarget: LeadFilterKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 5,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Filter Leads By Date And Phone Number",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  return target;
}

List<TargetFocus> appTargetFRLeadDashboard({
  required GlobalKey CreateLeadIconKey,
  required GlobalKey EditLeadIconKey,
  required GlobalKey DisplayLeadKey,
  required GlobalKey LeadFilterKey,
}) {
  List<TargetFocus> target = [];
  target.add(
    TargetFocus(
      identify: "Create Lead",
      keyTarget: CreateLeadIconKey,
      shape: ShapeLightFocus.Circle,
      alignSkip: Alignment.topRight,
      radius: 10,
      paddingFocus: 10,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Tap here to Open Lead Form",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Edit Lead",
      keyTarget: EditLeadIconKey,
      shape: ShapeLightFocus.Circle,
      alignSkip: Alignment.topRight,
      radius: 5,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Tap here to Edit a Created Lead",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Created Leads",
      keyTarget: DisplayLeadKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 5,
      paddingFocus: 10,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "List Of Leads Created",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  target.add(
    TargetFocus(
      identify: "Filter Leads",
      keyTarget: LeadFilterKey,
      shape: ShapeLightFocus.RRect,
      alignSkip: Alignment.topRight,
      radius: 5,
      paddingFocus: 5,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          builder: (context, controller) => const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Filter Leads By Phone Number",
              style: TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
  return target;
}