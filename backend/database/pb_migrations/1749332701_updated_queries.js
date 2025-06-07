/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_464205976")

  // remove field
  collection.fields.removeById("text3437106334")

  // add field
  collection.fields.addAt(3, new Field({
    "hidden": false,
    "id": "json3437106334",
    "maxSize": 0,
    "name": "output",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "json"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_464205976")

  // add field
  collection.fields.addAt(3, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text3437106334",
    "max": 0,
    "min": 0,
    "name": "output",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // remove field
  collection.fields.removeById("json3437106334")

  return app.save(collection)
})
