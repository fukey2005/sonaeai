enum RoomArea { tallFurniture, doorway, upperShelf }

typedef InspectionPhoto = ({
  RoomArea area,
  String photoKey,
  bool flagged,
  bool reviewed,
});

typedef RoomInspection = ({DateTime time, List<InspectionPhoto> photos});
