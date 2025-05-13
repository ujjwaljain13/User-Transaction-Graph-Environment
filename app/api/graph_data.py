from app.database.connection import db
from app.utils.serializers import serialize_neo4j_object
from typing import Dict, List, Any
from datetime import datetime

class GraphDataService:
    @staticmethod
    def get_graph_data() -> Dict[str, List[Dict[str, Any]]]:
        """
        Get all nodes and edges from the graph database in a format suitable for Cytoscape.js
        """
        # Get all nodes (users and transactions)
        nodes = GraphDataService._get_all_nodes()

        # Get all edges (relationships)
        edges = GraphDataService._get_all_edges()

        return {
            "nodes": nodes,
            "edges": edges
        }

    @staticmethod
    def _get_all_nodes() -> List[Dict[str, Any]]:
        """
        Get all nodes (users and transactions) from the graph database
        """
        query = """
        MATCH (n)
        WHERE n:User OR n:Transaction
        RETURN n
        """

        result = db.execute_query(query)

        nodes = []
        for record in result:
            node = record["n"]
            node_data = serialize_neo4j_object(node)

            # Convert datetime objects to strings
            for key, value in node_data.items():
                if isinstance(value, datetime):
                    node_data[key] = value.isoformat()

            # Create Cytoscape.js node format
            cytoscape_node = {
                "data": {
                    "id": node_data["id"],
                    "type": list(node.labels)[0] if node.labels else "Unknown",  # First label (User or Transaction)
                }
            }

            # Add label based on node type
            if "User" in node.labels:
                cytoscape_node["data"]["label"] = node_data.get("name", "Unknown User")
                # Add user-specific properties
                for key in ["email", "phone", "address", "entity_type", "company_name"]:
                    if key in node_data:
                        cytoscape_node["data"][key] = node_data[key]
            elif "Transaction" in node.labels:
                # Format transaction label
                amount = node_data.get("amount", 0)
                currency = node_data.get("currency", "USD")
                cytoscape_node["data"]["label"] = f"Transaction: {amount} {currency}"

                # Add transaction-specific properties
                for key in ["amount", "currency", "timestamp", "status", "ip_address", "device_id"]:
                    if key in node_data:
                        if key == "timestamp" and isinstance(node_data[key], datetime):
                            cytoscape_node["data"][key] = node_data[key].isoformat()
                        else:
                            cytoscape_node["data"][key] = node_data[key]

            nodes.append(cytoscape_node)

        return nodes

    @staticmethod
    def _get_all_edges() -> List[Dict[str, Any]]:
        """
        Get all edges (relationships) from the graph database
        """
        query = """
        MATCH (source)-[r]->(target)
        RETURN source.id AS source_id, target.id AS target_id, type(r) AS relationship_type, properties(r) AS properties
        """

        result = db.execute_query(query)

        edges = []
        for record in result:
            # Create Cytoscape.js edge format
            edge_id = f"{record['source_id']}-{record['relationship_type']}-{record['target_id']}"

            # Process properties to handle datetime objects
            properties = record["properties"]
            for key, value in properties.items():
                if isinstance(value, datetime):
                    properties[key] = value.isoformat()

            cytoscape_edge = {
                "data": {
                    "id": edge_id,
                    "source": record["source_id"],
                    "target": record["target_id"],
                    "relationship": record["relationship_type"],
                    "label": record["relationship_type"].replace("_", " "),
                    "properties": properties
                }
            }

            edges.append(cytoscape_edge)

        return edges
