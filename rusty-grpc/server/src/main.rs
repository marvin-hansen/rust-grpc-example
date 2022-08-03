// Let's build a gRPC server and client in Rust with tonic
// https://www.thorsten-hans.com/grpc-services-in-rust-with-tonic/

use tonic::{transport::Server, Request, Response, Status};
use voting::{VotingRequest, VotingResponse, voting_server::{Voting, VotingServer}};
use std::net::SocketAddr;

pub mod voting {
    tonic::include_proto!("voting");
}

#[derive(Debug, Default)]
pub struct VotingService;

#[tonic::async_trait]
impl Voting for VotingService {
    async fn vote(&self, request: Request<VotingRequest>) -> Result<Response<VotingResponse>, Status> {
        let r = request.into_inner();
        match r.vote {
            0 => Ok(Response::new(voting::VotingResponse { confirmation: {
                format!("Happy to confirm that you upvoted for {}", r.url)
            }})),
            1 => Ok(Response::new(voting::VotingResponse { confirmation: {
                format!("Confirmation that you downvoted for {}", r.url)
            }})),
            _ => Err(Status::new(tonic::Code::OutOfRange, "Invalid vote provided"))
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let server_details = "0.0.0.0:8080";
    let address: SocketAddr = server_details.parse().expect("Unable to parse socket address");

    let voting_service = VotingService::default();
    println!("Running voting service on port 8080");
    Server::builder().add_service(VotingServer::new(voting_service)).serve(address).await?;
    Ok(())
}
